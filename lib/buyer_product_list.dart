import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_method.dart';
import 'login_page.dart';
import 'firestore_id_generator.dart';

class BuyerProductList extends StatefulWidget {
  const BuyerProductList({super.key});

  @override
  BuyerProductListState createState() => BuyerProductListState();
}

class BuyerProductListState extends State<BuyerProductList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _conditionFilter = 'All';
  String _selectedCategory = 'All Categories';
  bool _isGridView = true;

  String? _effectiveBuyerUsername;

  final List<String> _categories = [
    'All Categories',
    'Electronics',
    'Fashion',
    'Books',
    'Home & Garden',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _effectiveBuyerUsername = currentUsername;
    _hydrateUsernameFromPrefsIfNeeded();
    authChangeNotifier.addListener(_handleAuthChange);
  }

  void _handleAuthChange() {
    if (!mounted) return;
    setState(() {
      _effectiveBuyerUsername = currentUsername;
    });
    _hydrateUsernameFromPrefsIfNeeded();
  }

  Future<void> _hydrateUsernameFromPrefsIfNeeded() async {
    if (_effectiveBuyerUsername != null && _effectiveBuyerUsername!.isNotEmpty)
      return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');
      if (!mounted) return;
      if (savedUsername != null && savedUsername.isNotEmpty) {
        setState(() {
          _effectiveBuyerUsername = savedUsername;
        });
      }
    } catch (_) {
      // Ignore; we'll fall back to global auth state.
    }
  }

  @override
  void dispose() {
    authChangeNotifier.removeListener(_handleAuthChange);
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    setState(() => _searchQuery = _searchController.text.trim());
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filter by condition',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('All'),
                      value: 'All',
                      groupValue: _conditionFilter,
                      onChanged: (v) {
                        setState(() => _conditionFilter = v!);
                        setModalState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('New'),
                      value: 'New',
                      groupValue: _conditionFilter,
                      onChanged: (v) {
                        setState(() => _conditionFilter = v!);
                        setModalState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Used Lightly'),
                      value: 'Used Lightly',
                      groupValue: _conditionFilter,
                      onChanged: (v) {
                        setState(() => _conditionFilter = v!);
                        setModalState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Used Heavily'),
                      value: 'Used Heavily',
                      groupValue: _conditionFilter,
                      onChanged: (v) {
                        setState(() => _conditionFilter = v!);
                        setModalState(() {});
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    final q = _searchQuery.toLowerCase();
    return items.where((prod) {
      final name = (prod['name'] ?? '').toString().toLowerCase();
      final condition = (prod['condition'] ?? '').toString();
      final category = (prod['category'] ?? 'Other').toString();

      final matchesSearch = name.contains(q);
      final matchesCondition =
          _conditionFilter == 'All' ||
          condition.toLowerCase() == _conditionFilter.toLowerCase();
      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          category == _selectedCategory;

      return matchesSearch && matchesCondition && matchesCategory;
    }).toList();
  }

  Future<void> _placeOrder(Map<String, dynamic> product) async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to buy products')),
      );
      return;
    }

    final buyerUsername = (_effectiveBuyerUsername ?? currentUsername)?.trim();
    if (buyerUsername == null || buyerUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login session missing. Please login again.'),
        ),
      );
      return;
    }

    final buyerNorm = buyerUsername.toLowerCase();
    final sellerNameNorm =
        (product['sellerName'] ?? '').toString().trim().toLowerCase();
    final sellerIdNorm =
        (product['sellerId'] ?? '').toString().trim().toLowerCase();
    if (sellerNameNorm.isNotEmpty && sellerNameNorm == buyerNorm ||
        sellerIdNorm.isNotEmpty && sellerIdNorm == buyerNorm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can't buy your own item."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Purchase'),
            content: Text(
              'Do you want to buy ${product['name']} for RM ${product['price'].toStringAsFixed(2)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Confirm Buy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final productId = (product['id'] ?? '').toString();
      if (productId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid product.')));
        return;
      }

      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId);
      final productSnap = await productRef.get();
      final productData = productSnap.data();
      final isAvailable = (productData?['isAvailable'] ?? true) == true;
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sorry, this product is no longer available.'),
          ),
        );
        return;
      }

      final orderId = await FirestoreIdGenerator.nextOrderId();
      // Mark as unavailable first so other users stop seeing it immediately.
      await productRef.update({'isAvailable': false});
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
          'productId': productId,
          'productName': product['name'],
          'price': product['price'],
          'buyerName': buyerUsername,
          'sellerName': product['sellerName'],
          'sellerId': product['sellerId'],
          'status': 'pending_payment',
          'quantity': 1,
          'orderDate': FieldValue.serverTimestamp(),
          'paymentMethod': 'unselected',
          'paymentStatus': 'unpaid',
        });
      } catch (e) {
        // If order write fails, restore availability.
        try {
          await productRef.update({'isAvailable': true});
        } catch (_) {}
        rethrow;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Force a rebuild so the orders-based filter engages immediately,
      // even if the products stream has not emitted a new snapshot.
      setState(() {});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => PaymentMethodPage(
                orderId: orderId,
                productName: (product['name'] ?? '').toString(),
                amount: (product['price'] ?? 0).toDouble(),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String imageUrl = product['imageUrl']?.toString() ?? '';

        return AlertDialog(
          title: Text(product['name'] ?? ''),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildSafeImage(imageUrl, height: 200),
                    ),
                  const SizedBox(height: 12),
                  Text('Category: ${product['category'] ?? 'Other'}'),
                  Text(
                    'Condition: ${product['condition'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Seller: ${product['sellerName'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: RM ${product['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(product['description'] ?? ''),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _placeOrder(product);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Buy Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSafeImage(String path, {double? height, double? width}) {
    if (path.isEmpty) return const Icon(Icons.image, size: 50);

    if (path.startsWith('http') || path.startsWith('blob')) {
      return Image.network(
        path,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorPlaceholder(height),
      );
    } else {
      // Local file paths are unreliable after project exports/moves
      // We check if the file actually exists before trying to render it
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            height: height,
            width: width ?? double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorPlaceholder(height),
          );
        }
      } catch (_) {}
      return _errorPlaceholder(height);
    }
  }

  Widget _errorPlaceholder(double? height) {
    return Container(
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsStream =
        FirebaseFirestore.instance.collection('products').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniMarketPlace'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => _updateSearchQuery(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.green),
                  onPressed: _showFilterDialog,
                ),
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.list : Icons.grid_view,
                    color: Colors.green,
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(30),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productsStream,
                builder: (context, productSnapshot) {
                  if (productSnapshot.hasError)
                    return const Center(child: Text('Error loading products'));
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  final docs = productSnapshot.data!.docs;
                  final products =
                      docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return {
                          'id': d.id,
                          'name': (data['name'] ?? '').toString(),
                          'price': (data['price'] ?? 0).toDouble(),
                          'imageUrl': (data['imageUrl'] ?? '').toString(),
                          'condition': (data['condition'] ?? '').toString(),
                          'description': (data['description'] ?? '').toString(),
                          'category': (data['category'] ?? 'Other').toString(),
                          'sellerName':
                              (data['sellerName'] ?? 'Unknown').toString(),
                          'sellerId': (data['sellerId'] ?? '').toString(),
                          // If missing, treat as available (for older docs).
                          'isAvailable': (data['isAvailable'] ?? true) == true,
                        };
                      }).toList();

                  // Global visibility: once any order is placed, product becomes unavailable for everyone.
                  final visibleProducts =
                      products.where((p) => p['isAvailable'] == true).toList();

                  // Prevent sellers from seeing/buying their own items by hiding
                  // their own products entirely in the buyer list.
                  final currentUserNorm =
                      (_effectiveBuyerUsername ?? currentUsername)
                          ?.trim()
                          .toLowerCase();
                  final notOwnProducts =
                      visibleProducts.where((p) {
                        if (currentUserNorm == null ||
                            currentUserNorm.isEmpty) {
                          return true;
                        }
                        final sellerNameNorm =
                            (p['sellerName'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                        final sellerIdNorm =
                            (p['sellerId'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                        final matchesSellerName =
                            sellerNameNorm.isNotEmpty &&
                            sellerNameNorm == currentUserNorm;
                        final matchesSellerId =
                            sellerIdNorm.isNotEmpty &&
                            sellerIdNorm == currentUserNorm;
                        return !(matchesSellerName || matchesSellerId);
                      }).toList();

                  final filtered = _applyFilters(notOwnProducts);
                  if (filtered.isEmpty)
                    return const Center(child: Text('No products found.'));

                  return _isGridView
                      ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: filtered.length,
                        itemBuilder:
                            (context, index) =>
                                _buildProductCard(filtered[index]),
                      )
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder:
                            (context, index) =>
                                _buildProductListTile(filtered[index]),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: _buildSafeImage(
                  product['imageUrl'],
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'RM ${product['price'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    product['condition'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Seller: ${product['sellerName']}',
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListTile(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: _buildSafeImage(product['imageUrl']),
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'RM ${product['price'].toStringAsFixed(2)}\nSeller: ${product['sellerName']}',
        ),
        isThreeLine: true,
        onTap: () => _showProductDetails(product),
      ),
    );
  }
}
