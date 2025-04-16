import 'package:flutter/material.dart';
import 'package:trade_twice/models/product.dart';

class CartService {
  // Singleton setup
  static final CartService instance = CartService._internal();

  CartService._internal();

  // Cart item list notifier
  final ValueNotifier<List<Items>> cartItems = ValueNotifier([]);

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
  }

  // Clear cart
  void clearCart() {
    cartItems.value = [];
  }

  // ✅ Calculate total price
  double getTotalPrice() {
    return cartItems.value.fold(
      0.0,
          (sum, item) => sum + (double.tryParse(item.sprice.toString()) ?? 0),
    );
  }
}
