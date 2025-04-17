import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_twice/models/product.dart';

class CartService {
  // Singleton setup
  static final CartService instance = CartService._internal();

  CartService._internal();

  // Cart item list notifier
  final ValueNotifier<List<Items>> cartItems = ValueNotifier([]);

  // Load cart from SharedPreferences
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cartItems');

    if (cartData != null) {
      final List<dynamic> decodedList = jsonDecode(cartData);
      final List<Items> loadedItems = decodedList.map((item) => Items.fromJson(item)).toList();
      cartItems.value = loadedItems;
    }
  }

  // Save cart to SharedPreferences
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = jsonEncode(cartItems.value.map((item) => item.toJson()).toList());
    prefs.setString('cartItems', cartData);
  }

  // Add to cart only if not already added
  void addToCart(Items item, BuildContext context) {
    final exists = cartItems.value.any((i) => i.id == item.id);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This item is already in the cart.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      cartItems.value = [...cartItems.value, item];
      saveCart(); // Save updated cart to SharedPreferences

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item added to cart.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Remove item from cart
  void removeFromCart(Items item) {
    cartItems.value = List.from(cartItems.value)..remove(item);
    saveCart(); // Save updated cart to SharedPreferences
  }

  // Clear cart
  void clearCart() {
    cartItems.value = [];
    saveCart(); // Save updated cart to SharedPreferences
  }

  // ✅ Calculate total price
  double getTotalPrice() {
    return cartItems.value.fold(
      0.0,
          (sum, item) => sum + (double.tryParse(item.sprice.toString()) ?? 0),
    );
  }
}
