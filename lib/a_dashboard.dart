import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'a_edit_profile.dart';
import 'login_page.dart';
import 'admin_manage_user.dart';
import 'admin_manage_product.dart';
import 'admin_manage_report.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  String userId = '';
  String name = '';
  String email = '';
  String imagePath = '';
  String password = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminFromDb();
  }

  Future<void> _loadAdminFromDb() async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        final data = doc.data();
        userId = doc.id;
        setState(() {
          name = (data['username'] ?? '').toString();
          email = (data['email'] ?? '').toString();
          password = (data['password'] ?? '').toString();
          imagePath = (data['userImage'] ?? '').toString();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ImageProvider _getAdminImage() {
    if (imagePath.isEmpty) return const AssetImage('img/admin.jpg');
    if (imagePath.startsWith('http') || imagePath.startsWith('blob')) {
      return NetworkImage(imagePath);
    }
    return FileImage(File(imagePath));
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Confirm Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.of(dCtx).pop(),
              child: const Text('No'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('username');
                await prefs.remove('role');
                if (!mounted) return;
                setState(() {
                  isLoggedIn = false;
                  currentUsername = null;
                  userRole = null;
                });
                authChangeNotifier.value = !authChangeNotifier.value;
                Navigator.of(dCtx).pop();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin page'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 80,
                backgroundImage: _getAdminImage(),
              ),
              const SizedBox(height: 12),
              Text(name.isNotEmpty ? name : 'Admin', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(email),
              const Text('UNIVERSITY MARKETPLACE'),
              const SizedBox(height: 36),
              _adminButton('Edit Profile', () async {
                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(userId: userId, name: name, email: email, password: password)));
                if (updated == true) _loadAdminFromDb();
              }),
              _adminButton('Manage User', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageUser()))),
              _adminButton('Manage Product', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageProduct()))),
              _adminButton('Manage Report', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageReportPage()))),
              const SizedBox(height: 40),
              TextButton(onPressed: _confirmLogout, child: const Text('Log Out the Account', style: TextStyle(color: Colors.green))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50), backgroundColor: Colors.green, foregroundColor: Colors.white),
        child: Text(label),
      ),
    );
  }
}
