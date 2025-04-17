import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:trade_twice/utils/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _profileUrl = '';
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not found");
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new user profile if doesn't exist
        await docRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': '',
          'profileUrl': '',
        });
      }

      final updatedDoc = await docRef.get();
      final data = updatedDoc.data();

      if (mounted && data != null) {
        setState(() {
          _name = data['name'] ?? '';
          _email = user.email ?? '';
          _phone = data['phone'] ?? '';
          _profileUrl = data['profileUrl'] ?? '';
          _nameController.text = _name;
          _phoneController.text = _phone;
          _isLoading = false; // ✅ Move here to guarantee the loader stops
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final file = File(pickedFile.path);
        final base64Image = base64Encode(await file.readAsBytes());

        const apiKey = '201ade4fc5fa5b05181c7f269517c8eb';

        final response = await http.post(
          Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey"),
          body: {
            "image": base64Image,
            "name": "profile_${DateTime.now().millisecondsSinceEpoch}",
          },
        );

        final data = jsonDecode(response.body);
        if (data['success']) {
          final imageUrl = data['data']['url'];
          final user = _auth.currentUser;
          if (user != null) {
            await _firestore.collection('users').doc(user.uid).update({
              'profileUrl': imageUrl,
            });
            if (mounted) {
              setState(() {
                _profileUrl = imageUrl;
                _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile image updated successfully!")),
              );
            }
          }
        } else {
          throw Exception("Image upload failed");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image upload failed: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 10-digit phone number")),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'phone': phone,
        });

        if (mounted) {
          setState(() {
            _name = name;
            _phone = phone;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        }
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _profileUrl.isNotEmpty
                      ? NetworkImage(_profileUrl)
                      : null,
                  child: _profileUrl.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                if (_isUploading)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.image),
              label: Text(_isUploading ? "Uploading..." : "Upload Profile Image"),
            ),
            const SizedBox(height: 20),
            _isEditing
                ? Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _name;
                          _phoneController.text = _phone;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _updateProfile,
                      child: const Text("Save Profile"),
                    ),
                  ],
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: $_name", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Email: $_email", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text(
                  "Phone: ${_phone.isNotEmpty ? _phone : "Not added"}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                  child: const Text("Edit Profile"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    MyRoutes.loginroute,
                        (route) => false,
                  );
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
