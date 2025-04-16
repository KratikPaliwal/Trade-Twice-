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
  String _profileUrl = '';
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              _name = data['name'] ?? '';
              _email = user.email ?? '';
              _profileUrl = data['profileUrl'] ?? '';
              _nameController.text = _name;
            });
          }
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'profileUrl': '',
          });

          setState(() {
            _name = user.displayName ?? '';
            _email = user.email ?? '';
            _nameController.text = _name;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: ${e.toString().substring(0, 100)}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        setState(() {
          _isUploading = true;
        });

        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        const apiKey = '201ade4fc5fa5b05181c7f269517c8eb'; // ← Replace this with your actual ImgBB API key

        final response = await http.post(
          Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey"),
          body: {
            "image": base64Image,
            "name": "profile_${DateTime.now().millisecondsSinceEpoch}",
          },
        );

        final data = jsonDecode(response.body);

        if (data['success']) {
          String imageUrl = data['data']['url'];

          final user = _auth.currentUser;
          if (user != null) {
            await _firestore.collection('users').doc(user.uid).update({
              'profileUrl': imageUrl,
            });

            setState(() {
              _profileUrl = imageUrl;
              _isUploading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile image updated successfully!")),
            );
          }
        } else {
          throw Exception("Image upload failed");
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      debugPrint("Image upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed: ${e.toString().substring(0, 100)}")),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _isLoading = true;
        });

        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
        });

        setState(() {
          _name = _nameController.text.trim();
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );

        _loadUserData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: ${e.toString().substring(0, 100)}")),
      );
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
          mainAxisSize: MainAxisSize.min,
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
            Text(
              _profileUrl.isEmpty ? "No profile image" : "Image URL loaded",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _isEditing
                ? ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.image),
              label: _isUploading
                  ? const Text("Uploading...")
                  : const Text("Upload Profile Image"),
            )
                : ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text("Change Profile Image"),
            ),
            const SizedBox(height: 20),
            _isEditing
                ? Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  MyRoutes.loginroute,
                      (route) => false,
                );
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
    super.dispose();
  }
}
