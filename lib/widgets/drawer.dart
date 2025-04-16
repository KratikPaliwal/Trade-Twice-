import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trade_twice/pages/login_page.dart';
import 'package:trade_twice/pages/profile_page.dart';
import 'package:trade_twice/Pages/my_products_page.dart';

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserImage();
  }

  Future<void> _loadUserImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          imageUrl = data['profileUrl'] ?? ''; // ✅ Use correct field
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserHeader(imageUrl: imageUrl),
          _buildDrawerItem(
            icon: CupertinoIcons.home,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: CupertinoIcons.profile_circled,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
            },
          ),
          _buildDrawerItem(
            icon: CupertinoIcons.cube_box,
            title: 'My Products',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductsPage()));
            },
          ),
          _buildDrawerItem(
            icon: CupertinoIcons.cart,
            title: 'Order',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        textScaleFactor: 1.2,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }
}

class UserHeader extends StatefulWidget {
  final String imageUrl;

  const UserHeader({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _UserHeaderState createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  String _displayName = "No Name";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _displayName = data['name'] ?? "No Name";
        _nameController.text = _displayName;
      });
    }
  }

  Future<void> _updateUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && newName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': newName,
      });
      setState(() {
        _displayName = newName;
        _isEditingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final imageUrl = widget.imageUrl;

    return Container(
      color: const Color(0xFFF97316),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditingName
                    ? TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (value) async {
                    await _updateUserName(value.trim());
                  },
                )
                    : Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditingName ? Icons.check : Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (_isEditingName) {
                          await _updateUserName(_nameController.text.trim());
                        }
                        setState(() {
                          _isEditingName = !_isEditingName;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
