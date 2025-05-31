import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/product_model.dart';
import 'image_carousel_widget.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;

        // Breakpoints responsifs
        final bool isXSmall = cardWidth < 160;
        final bool isSmall = cardWidth >= 160 && cardWidth < 220;
        final bool isMedium = cardWidth >= 220 && cardWidth < 300;
        final bool isLarge = cardWidth >= 300;

        // Tailles adaptatives
        final double titleFontSize = isXSmall ? 12 : (isSmall ? 14 : (isMedium ? 16 : 18));
        final double descriptionFontSize = isXSmall ? 9 : (isSmall ? 10 : (isMedium ? 12 : 14));
        final double priceFontSize = isXSmall ? 13 : (isSmall ? 15 : (isMedium ? 17 : 19));
        final double paddingValue = isXSmall ? 6 : (isSmall ? 8 : (isMedium ? 12 : 16));
        final double iconSize = isXSmall ? 14 : (isSmall ? 16 : (isMedium ? 18 : 20));
        final double buttonHeight = isXSmall ? 32 : (isSmall ? 36 : (isMedium ? 40 : 44));
        final double borderRadius = isXSmall ? 8 : (isSmall ? 10 : (isMedium ? 12 : 16));

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section image avec carousel
                Expanded(
                  flex: isXSmall ? 3 : (isSmall ? 2 : 2),
                  child: Stack(
                    children: [
                      ImageCarousel(
                        mainImageUrl: widget.product.imageUrl,
                        secondaryImages: widget.product.imagesSecondaires,
                        heroTag: 'product_${widget.product.id}',
                        iconSize: iconSize,
                        paddingValue: paddingValue,
                      ),

                      // Badge écologique
                      if (widget.product.estEcologique)
                        Positioned(
                          top: paddingValue * 0.5,
                          right: paddingValue * 0.5,
                          child: Container(
                            padding: EdgeInsets.all(paddingValue * 0.3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(paddingValue * 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: iconSize * 0.8,
                            ),
                          ),
                        ),

                      // Badge stock faible
                      if (widget.product.stock > 0 && widget.product.stock <= 5)
                        Positioned(
                          top: paddingValue * 0.5,
                          left: paddingValue * 0.5,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: paddingValue * 0.5,
                              vertical: paddingValue * 0.2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(paddingValue * 0.3),
                            ),
                            child: Text(
                              'Stock faible',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: descriptionFontSize * 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Contenu textuel
                Padding(
                  padding: EdgeInsets.all(paddingValue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du produit
                      Text(
                        widget.product.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: titleFontSize,
                          color: theme.textTheme.titleLarge?.color,
                          letterSpacing: -0.5,
                        ),
                        maxLines: isXSmall ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: paddingValue * 0.3),

                      // Description
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: descriptionFontSize,
                          height: 1.3,
                        ),
                        maxLines: isXSmall ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: paddingValue * 0.5),

                      // Prix et informations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.product.prix.toStringAsFixed(2)} \$',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: priceFontSize,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                if (widget.product.stock <= 10)
                                  Text(
                                    '${widget.product.stock} en stock',
                                    style: TextStyle(
                                      fontSize: descriptionFontSize * 0.9,
                                      color: widget.product.stock > 5
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: paddingValue * 0.6),

                      // Bouton d'ajout au panier
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: widget.product.stock > 0
                              ? () => _addToCart(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.product.stock > 0
                                ? theme.primaryColor
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius * 0.6),
                            ),
                            padding: EdgeInsets.symmetric(vertical: paddingValue * 0.4),
                          ),
                          child: Text(
                            widget.product.stock > 0
                                ? 'Ajouter au panier'
                                : 'Rupture de stock',
                            style: TextStyle(
                              fontSize: isXSmall ? 11 : (isSmall ? 12 : 14),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addToCart(BuildContext context) {
    context.read<CartController>().addToCart(widget.product, 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.product.nom} ajouté au panier',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Voir panier',
          textColor: Colors.white,
          onPressed: () {
            // Navigation vers le panier
          },
        ),
      ),
    );
  }
}