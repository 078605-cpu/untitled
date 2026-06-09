import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'validation.dart';

class AdminManageUser extends StatefulWidget {
  const AdminManageUser({super.key});

  @override
  AdminManageUserState createState() => AdminManageUserState();
}

class AdminManageUserState extends State<AdminManageUser> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _roleFilter,
              isExpanded: true,
              items: ['All', 'admin', 'seller', 'buyer'].map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _roleFilter = val!),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var username = (data['username'] ?? '').toString().toLowerCase();
                  var role = (data['role'] ?? '').toString();
                  
                  bool matchesSearch = username.contains(_searchQuery);
                  bool matchesRole = _roleFilter == 'All' || role == _roleFilter;
                  
                  return matchesSearch && matchesRole;
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String? imageUrl = (data['userImage'] ?? '').toString();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl.isNotEmpty 
                            ? (imageUrl.startsWith('http') ? NetworkImage(imageUrl) : FileImage(File(imageUrl)) as ImageProvider)
                            : null,
                        child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(data['username'] ?? 'No Name'),
                      subtitle: Text(data['role'] ?? ''),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailsPage(userId: docs[index].id, userData: data),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailsPage({super.key, required this.userId, required this.userData});

  @override
  UserDetailsPageState createState() => UserDetailsPageState();
}

class UserDetailsPageState extends State<UserDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  String? _imagePath;
  late String _role;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['username']?.toString());
    _emailController = TextEditingController(text: widget.userData['email']?.toString());
    _addressController = TextEditingController(text: widget.userData['address']?.toString() ?? '');
    _passwordController = TextEditingController(text: widget.userData['password']?.toString());
    _phoneController = TextEditingController(text: widget.userData['phone']?.toString() ?? '');
    _imagePath = widget.userData['userImage']?.toString();
    _role = widget.userData['role'] ?? 'buyer';
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Profile'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isAdmin) // Admin cannot be deleted
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green,
                  backgroundImage: _imagePath != null && _imagePath!.isNotEmpty
                      ? (_imagePath!.startsWith('http') ? NetworkImage(_imagePath!) : FileImage(File(_imagePath!)) as ImageProvider)
                      : null,
                  child: _imagePath == null || _imagePath!.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: ['admin', 'seller', 'buyer'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _role = val!),
            ),
            const SizedBox(height: 16),
            Text('Matriks: ${widget.userData['matriksNumber']} (Cannot change)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _confirmUpdate(context),
                child: const Text('Update User', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          // Raised No button
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('No', style: TextStyle(color: Colors.white)),
          ),
          // lame Yes button
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _confirmUpdate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Do you want to update this user\'s info?'),
        actions: [
          // lame No button
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No', style: TextStyle(color: Colors.grey))),
          // Raised Yes button (Constructive)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final email = _emailController.text.trim();
              final phone = _phoneController.text.trim();

              final emailError = Validation.requiredEmail(email);
              if (emailError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError), backgroundColor: Colors.red));
                return;
              }

              final phoneError = Validation.requiredPhone(phone);
              if (phoneError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneError), backgroundColor: Colors.red));
                return;
              }

              await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                'username': _nameController.text.trim(),
                'email': email,
                'address': _addressController.text.trim(),
                'phone': phone,
                'password': _passwordController.text,
                'userImage': _imagePath ?? '',
                'role': _role,
              });
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully!')));
            },
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
