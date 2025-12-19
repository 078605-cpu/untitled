// lib/seller_manage_product_page.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'product_model.dart';      // Import the model
import 'seller_view_products_page.dart'; // UPDATED import path

// Main page for managing products
class ManageProductPage extends StatelessWidget {
  const ManageProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Your Products'),
        backgroundColor: const Color(0xFF386356),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Button to add a new product
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('Add New Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D6B5D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Show form for ADDING (no product data passed)
                  _showProductFormDialog(context);
                },
              ),
              const SizedBox(height: 20),
              // Button to view existing products
              ElevatedButton.icon(
                icon: const Icon(Icons.view_list_outlined, color: Color(0xFF2D5A4C)),
                label: const Text('View All Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4D3D0),
                  foregroundColor: const Color(0xFF2D5A4C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Navigate to the ViewProductsPage
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ViewProductsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductFormDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Pass the product if we are updating, otherwise it's null
        return AddProductForm(productToUpdate: product);
      },
    );
  }
}

// This form is now smart: it can handle both ADDING and UPDATING.
class AddProductForm extends StatefulWidget {
  // If a product is passed here, the form is in 'update' mode.
  // If it's null, the form is in 'add' mode.
  final Product? productToUpdate;

  const AddProductForm({super.key, this.productToUpdate});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  late String _productName, _description;
  late double _price;
  late String _condition;
  String? _imageUrl; // To store image URL
  bool _isLoading = false;

  final List<String> _conditions = ['New', 'Lightly Used', 'Heavily Used'];

  @override
  void initState() {
    super.initState();
    // If we are updating, pre-fill the form fields with existing data.
    if (widget.productToUpdate != null) {
      final product = widget.productToUpdate!;
      _productName = product.name;
      _description = product.description;
      _price = product.price;
      _condition = product.condition;
      _imageUrl = product.imageUrl;
    } else {
      // Otherwise, set default values for a new product.
      _productName = '';
      _description = '';
      _price = 0.0;
      _condition = 'New';
      _imageUrl = null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    // Determine if we are adding or updating
    final isUpdating = widget.productToUpdate != null;
    bool success = await _saveToDatabase(isUpdating: isUpdating);

    if (!mounted) return;
    Navigator.of(context).pop();

    final message = isUpdating
        ? (success ? 'Product updated successfully!' : 'Failed to update product.')
        : (success ? 'Product added successfully!' : 'Failed to add product.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Future<bool> _saveToDatabase({required bool isUpdating}) async {
    await Future.delayed(const Duration(seconds: 2));

    if (isUpdating) {
      print('UPDATING product in database: ${widget.productToUpdate!.id}');
      // Here you would find the product in your database and update it.
    } else {
      print('ADDING new product to database.');
      // Here you would add a new product.
    }

    print('Name: $_productName, Price: $_price, Condition: $_condition');
    return Random().nextBool();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.productToUpdate != null;
    return AlertDialog(
      title: Text(isUpdating ? 'Update Product' : 'Add New Product', textAlign: TextAlign.center),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _productName,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _productName = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _price > 0 ? _price.toString() : '',
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Enter a valid price' : null,
                onSaved: (value) => _price = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 20),
              // Image handling section
              if (isUpdating && _imageUrl != null)
                Column(
                  children: [
                    const Text('Current Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Image.network(_imageUrl!, height: 60),
                    TextButton(
                      child: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                      onPressed: () => setState(() => _imageUrl = null),
                    ),
                  ],
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(isUpdating ? 'Upload New Image' : 'Upload Image'),
                onPressed: () => print('Image upload functionality to be added.'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D6B5D), foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
