import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProductsPage extends StatefulWidget {
  @override
  _AddProductsPageState createState() => _AddProductsPageState();
}

class _AddProductsPageState extends State<AddProductsPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  List<File> _images = [];

  String title = '';
  String description = '';
  String buyPrice = '';
  String sellPrice = '';
  final String imgbbApiKey = '201ade4fc5fa5b05181c7f269517c8eb'; // Your API key

  Future<void> pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only select up to 3 images.")),
      );
      return;
    }

    if (Platform.isAndroid) {
      var permissionStatus = await Permission.photos.request();
      if (!permissionStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission denied to access images.")),
        );
        return;
      }
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<List<String>> uploadImagesToImgBB() async {
    List<String> imageUrls = [];

    for (File image in _images) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey"),
        body: {"image": base64Image},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 200) {
        imageUrls.add(responseData['data']['url']);
      } else {
        throw Exception("Image upload failed: ${responseData['error']['message']}");
      }
    }

    return imageUrls;
  }

  Future<void> submitProduct() async {
    if (_formKey.currentState!.validate() && _images.isNotEmpty) {
      _formKey.currentState!.save();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final imageUrls = await uploadImagesToImgBB();

        await FirebaseFirestore.instance.collection('products').add({
          'title': title,
          'description': description,
          'buyPrice': int.parse(buyPrice),
          'sellPrice': int.parse(sellPrice),
          'images': imageUrls,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Product submitted successfully!")),
        );

        Navigator.pushReplacementNamed(context, '/home'); // ✅ Direct to HomePage
      } catch (e) {
        print("Error uploading product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading product: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and add at least 1 image.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _images
                    .map((image) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ))
                    .toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickImage,
                child: Text("Select Image"),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Product Title'),
                onSaved: (value) => title = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Bought For (₹)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => buyPrice = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Sell For (₹)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => sellPrice = value ?? '',
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitProduct,
                child: Text("Submit Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
