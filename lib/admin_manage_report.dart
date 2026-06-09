import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageReportPage extends StatefulWidget {
  const AdminManageReportPage({super.key});

  @override
  State<AdminManageReportPage> createState() => _AdminManageReportPageState();
}

class _AdminManageReportPageState extends State<AdminManageReportPage> {
  bool _allTime = true;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.green[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading report'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('No sales data yet.'));
          }

          final orders = docs
              .map((d) => _OrderRow(id: d.id, data: (d.data() as Map<String, dynamic>?) ?? const {}))
              .toList();

          // Sales report is based on PAID orders (and not cancelled).
          final paidOrdersAllTime = orders.where((o) => o.paymentStatus == 'paid' && o.status != 'cancelled').toList();

          // Group paid orders by month.
          final paidByMonth = <_YearMonth, List<_OrderRow>>{};
          for (final o in paidOrdersAllTime) {
            final dt = o.bestTimestampDateTime;
            if (dt == null) continue;
            final ym = _YearMonth(dt.year, dt.month);
            (paidByMonth[ym] ??= <_OrderRow>[]).add(o);
          }

          final paidOrdersScope = _allTime
              ? paidOrdersAllTime
              : paidOrdersAllTime.where((o) {
                  final dt = o.bestTimestampDateTime;
                  if (dt == null) return false;
                  return dt.year == _selectedYear && dt.month == _selectedMonth;
                }).toList();

          final totalRevenueScope = paidOrdersScope.fold<double>(0.0, (total, o) => total + (o.price * o.quantity));

          // All-time high month (based on paid revenue).
          _YearMonth? bestMonth;
          double bestRevenue = 0.0;
          for (final entry in paidByMonth.entries) {
            final revenue = entry.value.fold<double>(0.0, (total, o) => total + (o.price * o.quantity));
            if (bestMonth == null || revenue > bestRevenue) {
              bestMonth = entry.key;
              bestRevenue = revenue;
            }
          }

          // For the other counters, keep them aligned with the same selected month.
          // We use the same timestamp source as the sales grouping.
          final scopedAllOrders = _allTime
              ? orders
              : orders.where((o) {
                  final dt = o.bestTimestampDateTime;
                  if (dt == null) return false;
                  return dt.year == _selectedYear && dt.month == _selectedMonth;
                }).toList();
          final totalOrdersScope = scopedAllOrders.length;
          final cancelledOrdersScope = scopedAllOrders.where((o) => o.status == 'cancelled').length;
          final unpaidOrdersScope = scopedAllOrders.where((o) => o.paymentStatus != 'paid' && o.status != 'cancelled').length;

          final revenueBySeller = <String, _SellerTotals>{};
          for (final o in paidOrdersScope) {
            final key = (o.sellerName.isNotEmpty ? o.sellerName : 'Unknown');
            final existing = revenueBySeller[key];
            if (existing == null) {
              revenueBySeller[key] = _SellerTotals(revenue: o.price * o.quantity, orders: 1);
            } else {
              revenueBySeller[key] = _SellerTotals(
                revenue: existing.revenue + (o.price * o.quantity),
                orders: existing.orders + 1,
              );
            }
          }

          final sellerRows = revenueBySeller.entries.toList()
            ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('Filter', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedYear,
                          items: _yearOptions().map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                          onChanged: _allTime
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _selectedYear = v);
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedMonth,
                          items: List.generate(12, (i) {
                            final m = i + 1;
                            return DropdownMenuItem(value: m, child: Text(_monthLabel(m)));
                          }),
                          onChanged: _allTime
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _selectedMonth = v);
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _allTime = !_allTime;
                          });
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                        child: Text(_allTime ? 'All time' : 'Monthly'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'All-time High Month',
                value: bestMonth == null ? 'N/A' : '${bestMonth.label} • RM ${bestRevenue.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: _allTime ? 'Total Revenue (Paid)' : 'Revenue (Paid) • ${_selectedYear.toString()}-${_selectedMonth.toString().padLeft(2, '0')}',
                value: 'RM ${totalRevenueScope.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Paid Orders',
                      value: paidOrdersScope.length.toString(),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Unpaid Orders',
                      value: unpaidOrdersScope.toString(),
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Orders',
                      value: totalOrdersScope.toString(),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Cancelled',
                      value: cancelledOrdersScope.toString(),
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Revenue by Seller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (sellerRows.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No paid orders yet.')))
              else
                ...sellerRows.map((e) {
                  return Card(
                    child: ListTile(
                      title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Paid orders: ${e.value.orders}'),
                      trailing: Text(
                        'RM ${e.value.revenue.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _YearMonth {
  final int year;
  final int month;

  const _YearMonth(this.year, this.month);

  String get label {
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm';
  }

  int compareTo(_YearMonth other) {
    final a = year * 100 + month;
    final b = other.year * 100 + other.month;
    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) => other is _YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

List<int> _yearOptions() {
  // Allow selecting years in the past even if no data exists yet.
  // Adjust range here if you want more/less history.
  final now = DateTime.now();
  const start = 2000;
  final end = now.year;
  return [
    for (var y = end; y >= start; y--) y,
  ];
}

String _monthLabel(int month) {
  const names = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (month < 1 || month > 12) return month.toString();
  return names[month - 1];
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final bool compact;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerTotals {
  final double revenue;
  final int orders;

  const _SellerTotals({required this.revenue, required this.orders});
}

class _OrderRow {
  final String id;
  final Map<String, dynamic> data;

  const _OrderRow({required this.id, required this.data});

  String get sellerName => (data['sellerName'] ?? '').toString();

  String get status => (data['status'] ?? 'pending').toString().toLowerCase();

  String get paymentStatus => (data['paymentStatus'] ?? 'unpaid').toString().toLowerCase();

  DateTime? get bestTimestampDateTime {
    // Prefer payment timestamp when available, else fall back to orderDate.
    final paidAt = data['paidAt'];
    final orderDate = data['orderDate'];
    return _asDateTime(paidAt) ?? _asDateTime(orderDate);
  }

  double get price {
    final v = data['price'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  int get quantity {
    final v = data['quantity'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 1;
  }
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  // Sometimes values end up as milliseconds.
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
