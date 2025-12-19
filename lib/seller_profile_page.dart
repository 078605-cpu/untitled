import 'package:flutter/material.dart';
import 'seller_manage_product_page.dart'; // Import the new page

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use the app's primary color for the AppBar
        backgroundColor: const Color(0xFF386356),
        // Ensure title text is readable
        foregroundColor: Colors.white,
        title: const Text('Seller Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?q=80&w=2585&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                backgroundColor: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Seller Name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Using a Column now for better spacing and alignment
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "Manage Product" Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageProductPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.store, color: Colors.white),
                    label: const Text('Manage Product'),
                    style: ElevatedButton.styleFrom(
                      // Use the main button color from the login screen
                      backgroundColor: const Color(0xFF3D6B5D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // "Update Orders" Button
                  ElevatedButton.icon(
                    onPressed: () {
                      print('Update Orders button pressed');
                    },
                    icon: const Icon(Icons.receipt, color: Color(0xFF2D5A4C)),
                    label: const Text('Update Orders'),
                    style: ElevatedButton.styleFrom(
                      // Use the secondary button color from the login screen
                      backgroundColor: const Color(0xFFC4D3D0),
                      foregroundColor: const Color(0xFF2D5A4C),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
