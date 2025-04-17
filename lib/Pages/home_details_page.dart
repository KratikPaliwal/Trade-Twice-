import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trade_twice/models/product.dart';
import 'package:trade_twice/Pages/cart_services.dart';
import 'package:trade_twice/Pages/order_page.dart';
import 'package:trade_twice/Pages/profile_page.dart';

class HomeDetailsPage extends StatelessWidget {
  final Items item;

  const HomeDetailsPage({Key? key, required this.item}) : super(key: key);

  Future<bool> hasPhoneNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    return data != null &&
        data['phone'] != null &&
        data['phone'].toString().trim().isNotEmpty;
  }

  void showPhoneSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Please update your phone number in profile."),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Update',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade Twice',
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderPage()),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: ValueListenableBuilder<List<Items>>(
                  valueListenable: CartService.instance.cartItems,
                  builder: (context, cartItems, child) {
                    return cartItems.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                      padding: const EdgeInsets.all(2),
                      decoration:
                      const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.network(item.imageurl, height: 200)),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              item.des,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '₹${item.bprice}',
                  style: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${item.sprice}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    if (await hasPhoneNumber()) {
                      CartService.instance.addToCart(item, context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to cart!'),
                          backgroundColor: Colors.black,
                        ),
                      );
                    } else {
                      showPhoneSnackbar(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () async {
                    if (await hasPhoneNumber()) {
                      CartService.instance.addToCart(item, context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderPage()),
                      );
                    } else {
                      showPhoneSnackbar(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}