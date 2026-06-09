import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageProduct extends StatefulWidget {
  const AdminManageProduct({super.key});

  @override
  AdminManageProductState createState() => AdminManageProductState();
}

class AdminManageProductState extends State<AdminManageProduct> {
  String? _selectedSellerId;
  String? _selectedSellerName;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.green,
        leading: _selectedSellerId != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _selectedSellerId = null;
                _selectedSellerName = null;
                _searchQuery = '';
                _searchController.clear();
              }),
            )
          : null,
      ),
      body: _selectedSellerId == null 
        ? _buildSellerList() 
        : _buildProductList(), // Changed to list layout
    );
  }

  Widget _buildSellerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'seller')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sellers = snapshot.data!.docs;
        if (sellers.isEmpty) return const Center(child: Text('No sellers found.'));

        return ListView.builder(
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final data = sellers[index].data() as Map<String, dynamic>;
            final name = data['username'] ?? 'Unknown Seller';
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.store)),
              title: Text(name),
              subtitle: Text(data['email'] ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() {
                _selectedSellerId = name; 
                _selectedSellerName = name;
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildProductList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by $_selectedSellerName...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('sellerName', isEqualTo: _selectedSellerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final products = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

              if (products.isEmpty) return const Center(child: Text('No products found for this seller.'));

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final data = products[index].data() as Map<String, dynamic>;
                  final productId = products[index].id;
                  return Card(
                    child: ListTile(
                      leading: data['imageUrl'] != null && data['imageUrl'] != ''
                          ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text('RM ${data['price']}'),
                      onTap: () => _showProductDetails(context, data, productId),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> data, String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['name'] ?? 'Product Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != '')
              Image.network(data['imageUrl'], height: 150, fit: BoxFit.cover),
            const SizedBox(height: 10),
            Text(data['description'] ?? 'No description provided.'),
          ],
        ),
        actions: [
          // LAME DELETE
          TextButton(
            onPressed: () => _showDeleteReasonDialog(context, productId),
            child: const Text('Delete Product', style: TextStyle(color: Colors.red)),
          ),
          // PROMINENT CLOSE
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteReasonDialog(BuildContext context, String productId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reason for Deletion'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Enter reason here...'),
        ),
        actions: [
          // PROMINENT CANCEL
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          // LAME DELETE (Enabled only if reason is provided)
          StatefulBuilder(
            builder: (context, setState) => TextButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                // You can save the reason to a logs collection here if needed
                await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                if (!mounted) return;
                Navigator.pop(ctx); // Close reason dialog
                Navigator.pop(context); // Close details dialog
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
              },
              child: const Text('Confirm Delete', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
