import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'purchase_history.dart';

class BuyerList extends StatefulWidget {
  const BuyerList({super.key});

  @override
  _BuyerListState createState() => _BuyerListState();
}

class _BuyerListState extends State<BuyerList> {
  List<Map<String, String>> buyers = [
    {
      'username': 'buyer_ahmad',
      'userID': 'B001',
      'nophone': '0123456789',
      'address': '123 Jalan Mawar, KL'
    },
    {
      'username': 'buyer_lisa',
      'userID': 'B002',
      'nophone': '0198765432',
      'address': '45 Jalan Melati, PJ'
    },
  ];

  int get nextUserIdNumber {
    if (buyers.isEmpty) return 1;
    final ids = buyers.map((b) => int.tryParse(b['userID']!.substring(1)) ?? 0).toList();
    return (ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1;
  }

  void _addBuyerDialog() {
    final rootContext = context;
    final usernameController = TextEditingController();
    final nophoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Buyer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: nophoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = nophoneController.text.trim();
              if (!RegExp(r'^\d+$').hasMatch(phone) || (phone.length != 10 && phone.length != 11)) {
                ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Phone number must be 10 or 11 digits (numbers only).'), backgroundColor: Colors.red));
                return;
              }
              setState(() {
                buyers.add({
                  'username': usernameController.text,
                  'userID': 'B${nextUserIdNumber.toString().padLeft(3, '0')}',
                  'nophone': nophoneController.text,
                  'address': addressController.text,
                });
              });
              Navigator.pop(dialogContext);
              // Show success dialog
              showDialog(
                context: rootContext,
                builder: (context) => AlertDialog(
                  title: Text('Success'),
                  content: Text('Buyer added successfully!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateBuyerDialog(int index) {
    final rootContext = context;
    final buyer = buyers[index];
    final usernameController = TextEditingController(text: buyer['username']);
    final nophoneController = TextEditingController(text: buyer['nophone']);
    final addressController = TextEditingController(text: buyer['address']);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Buyer'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: nophoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Show confirmation dialog before updating
              showDialog(
                context: dialogContext,
                builder: (confirmContext) => AlertDialog(
                  title: Text('Confirm Update'),
                  content: Text('Are you sure you want to update this buyer?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmContext),
                      child: Text('No'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final phone = nophoneController.text.trim();
                        if (!RegExp(r'^\d+$').hasMatch(phone) || (phone.length != 10 && phone.length != 11)) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Phone number must be 10 or 11 digits (numbers only).'), backgroundColor: Colors.red));
                          return;
                        }
                        setState(() {
                          buyers[index] = {
                            'username': usernameController.text,
                            'userID': buyer['userID']!,
                            'nophone': nophoneController.text,
                            'address': addressController.text,
                          };
                        });
                        Navigator.pop(confirmContext); // Close confirmation
                        Navigator.pop(dialogContext); // Close update dialog
                      },
                      child: Text('Yes'),
                    ),
                  ],
                ),
              );
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteBuyer(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this buyer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                buyers.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Buyers'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('UserID')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: buyers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var buyer = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseHistoryPage(
                                  username: buyer['username'] ?? '',
                                  userID: buyer['userID'] ?? '',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            buyer['username'] ?? '',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(buyer['userID'] ?? '')),
                      DataCell(Text(buyer['nophone'] ?? '')),
                      DataCell(Text(buyer['address'] ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBuyer(idx),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateBuyerDialog(idx),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _addBuyerDialog,
              icon: Icon(Icons.add),
              label: Text('Add Buyer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}