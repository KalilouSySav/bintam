import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/cart_item_model.dart';

class CartItemWidget extends StatelessWidget {
  final CartItemModel item;

  const CartItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final Uint8List imageBytes = base64Decode(item.imageUrl);
    final String imageUrl = item.imageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Image + Nom + Prix
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(imageUrl),
                const SizedBox(width: 12),
                Expanded(child: _buildTitleAndPrice()),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuantitySelector(context),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix: ${item.sousTotal.toStringAsFixed(2)} CFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<CartController>().removeFromCart(item.id);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: item.imageUrl.isNotEmpty
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image);
        },
      )
          : const Icon(Icons.image),
    );
  }

  Widget _buildTitleAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${item.prix.toStringAsFixed(2)} CFA / unité',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    return Row(
      children: [
        const Text(
          "Quantité :",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            context.read<CartController>().updateQuantity(item.id, item.quantite - 1);
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '${item.quantite}',
          style: const TextStyle(fontSize: 16),
        ),
        IconButton(
          onPressed: () {
            context.read<CartController>().updateQuantity(item.id, item.quantite + 1);
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
