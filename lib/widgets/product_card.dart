import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // Changed from Cupertino to Material for consistency with Scaffold
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Uint8List imageBytes = base64Decode(product.imageUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        // Define breakpoints for responsiveness within the card
        final bool isSmallCard = cardWidth < 200;
        final bool isMediumCard = cardWidth >= 200 && cardWidth < 300;
        // You can add more breakpoints if needed

        double titleFontSize = isSmallCard ? 14 : (isMediumCard ? 16 : 18);
        double descriptionFontSize = isSmallCard ? 10 : (isMediumCard ? 12 : 14);
        double priceFontSize = isSmallCard ? 14 : (isMediumCard ? 16 : 18);
        double paddingValue = isSmallCard ? 8 : 12;
        double iconSize = isSmallCard ? 16 : 20;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Slightly more rounded corners
          ),
          clipBehavior: Clip.antiAlias, // Ensures content respects card border
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isSmallCard ? 3 : 2, // Adjust image flex for small cards
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    // Removed top borderRadius here as it's handled by Card's shape
                  ),
                  child: product.imageUrl.isNotEmpty
                      ? Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
                    },
                  )
                      : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(paddingValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                      ),
                      maxLines: isSmallCard ? 2 : 1, // Limit lines based on card size
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallCard ? 2 : 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: descriptionFontSize,
                      ),
                      maxLines: isSmallCard ? 2 : 2, // Ensure description wraps well
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallCard ? 4 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.prix.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: priceFontSize,
                            color: Colors.green,
                          ),
                        ),
                        if (product.estEcologique)
                          Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: iconSize,
                          ),
                      ],
                    ),
                    SizedBox(height: isSmallCard ? 4 : 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product.stock > 0
                            ? () => _addToCart(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallCard ? 8 : 12), // Adjust button padding
                          textStyle: TextStyle(fontSize: isSmallCard ? 12 : 14), // Adjust button text size
                        ),
                        child: Text(
                          product.stock > 0 ? 'Ajouter au panier' : 'Rupture de stock',
                          textAlign: TextAlign.center, // Center text in button
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCart(BuildContext context) {
    context.read<CartController>().addToCart(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.nom} ajouté au panier'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}