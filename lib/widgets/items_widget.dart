import 'package:flutter/material.dart';
import 'package:trade_twice/models/product.dart';
import 'package:trade_twice/utils/routes.dart';

class ItemsWidget extends StatelessWidget {
  final Items item;

  const ItemsWidget({Key? key, required this.item}) : super(key: key);

  void navigateToDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      MyRoutes.homedetails,
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToDetails(context), // tapping card
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xfff5f5f5),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Center(
                child: Image.network(
                  item.imageurl,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Product Name
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Product Description
            Text(
              item.des,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Prices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${item.bprice}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '₹${item.sprice}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Buy Now Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => navigateToDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
