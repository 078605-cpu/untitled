import 'package:flutter/material.dart';

void main() {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark green background
      backgroundColor: const Color(0xFF2D5A4C),
      body: Stack(
        children: [
          // White curved container at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // Illustration Placeholder
                  Center(
                    child: Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3D6B5D),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.moped, size: 100, color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Branding
                  const Text(
                    'My',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4B41A),
                    ),
                  ),
                  const Text(
                    'Shopping APP',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Input Fields
                  _buildTextField(Icons.person, 'Email or Phone'),
                  const SizedBox(height: 15),
                  _buildTextField(Icons.lock, 'Password', isObscure: true),
                  const SizedBox(height: 15),
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                  // Login Button
                  _buildButton(
                    text: 'Login',
                    color: const Color(0xFF3D6B5D),
                    textColor: Colors.white,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
                  ),
                  // Create Account Button
                  _buildButton(
                    text: 'Create an account',
                    color: const Color(0xFFC4D3D0),
                    textColor: const Color(0xFF2D5A4C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for TextFields
  Widget _buildTextField(IconData icon, String hint, {bool isObscure = false}) {
    return TextField(
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  // Helper method for Buttons
  Widget _buildButton({required String text, required Color color, required Color textColor}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        onPressed: () {},
        child: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}