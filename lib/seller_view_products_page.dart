// lib/seller_view_products_page.dart

import 'package:flutter/material.dart';
import 'product_model.dart'; // Import the data model
import 'seller_manage_product_page.dart'; // We need the AddProductForm from here

class ViewProductsPage extends StatefulWidget {
  const ViewProductsPage({super.key});

  @override
  State<ViewProductsPage> createState() => _ViewProductsPageState();
}

class _ViewProductsPageState extends State<ViewProductsPage> {
  // --- MOCK DATABASE ---
  // In a real app, this data would be fetched from Firebase, etc.
  // We add one sample product to start with.
  List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Vintage Leather Jacket',
      description: 'A stylish jacket from the 80s.',
      price: 150.00,
      condition: 'Lightly Used',
      imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500',
    )
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Simulate fetching products from a database
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, you would fetch from your database here.
    // Since we are using a local list, we just stop the loading indicator.
    setState(() => _isLoading = false);
  }

  // Function to show the update form
  void _showUpdateForm(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // We reuse the AddProductForm but pass the existing product data to it
        return AddProductForm(productToUpdate: product);
      },
    ).then((_) => _fetchProducts()); // Refresh list after dialog closes
  }

  // Function to show the delete confirmation dialog
  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              // --- DELETE LOGIC ---
              setState(() {
                _products.removeWhere((p) => p.id == product.id);
              });
              print('Product ${product.id} deleted.');
              Navigator.of(ctx).pop(); // Close the dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        backgroundColor: const Color(0xFF386356),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchProducts,
        child: _products.isEmpty
            ? const Center(child: Text('You have no products yet.'))
            : ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: product.imageUrl != null
                      ? NetworkImage(product.imageUrl!)
                      : null,
                  child: product.imageUrl == null
                      ? const Icon(Icons.inventory_2_outlined)
                      : null,
                ),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('\$${product.price.toStringAsFixed(2)} - ${product.condition}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Update Icon Button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showUpdateForm(product),
                    ),
                    // Delete Icon Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(product),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
