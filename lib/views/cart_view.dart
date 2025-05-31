import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/checkout_dialog.dart';
import '../widgets/nav_button.dart';

class CartView extends StatelessWidget {
  const CartView({Key? key}) : super(key: key);

  // Fonction utilitaire pour sécuriser les tailles responsive
  double clampDouble(double value, double min, double max) {
    return value.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: isDesktop ? 2 : 1,
        title: isDesktop
            ? Row(
          children: [
            Image.asset(
              'images/logo-bintam-1.png',
              height: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              'BintaM',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            NavButton(label: 'Accueil', route: '/'),
            NavButton(label: 'Catalogue', route: '/catalogue'),
            NavButton(label: 'Contact', route: '/contact'),
          ],
        )
            : const Text('Panier'),
        actions: [
          Consumer<AuthController>(
            builder: (context, auth, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.person, color: Colors.black),
                onSelected: (value) {
                  switch (value) {
                    case 'auth':
                      context.go('/auth');
                      break;
                    case 'admin':
                      context.go('/admin');
                      break;
                    case 'visitor':
                      auth.setVisitorMode();
                      break;
                    case 'logout':
                      auth.signOut();
                      break;
                  }
                },
                itemBuilder: (context) {
                  if (auth.isAuthenticated) {
                    return [
                      PopupMenuItem(
                        value: 'profile',
                        child: Text('${auth.currentUser?.prenom} ${auth.currentUser?.nom}'),
                      ),
                      if (auth.isAdmin)
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text('Administration'),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Déconnexion'),
                      ),
                    ];
                  } else {
                    return [
                      const PopupMenuItem(
                        value: 'auth',
                        child: Text('Connexion'),
                      ),
                      const PopupMenuItem(
                        value: 'visitor',
                        child: Text('Mode Visiteur'),
                      ),
                    ];
                  }
                },
              );
            },
          ),
        ],
        automaticallyImplyLeading: !isDesktop,
      ),
      drawer: isDesktop ? null : const AppDrawer(),
      body: Consumer<CartController>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;
                final double availableHeight = constraints.maxHeight;

                final double iconSize = clampDouble(availableWidth * 0.13, 50, 100);
                final double textFontSize = clampDouble(availableWidth * 0.04, 14, 24);
                final double spacingHeight = availableHeight * 0.02;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: iconSize,
                        color: Colors.black,
                      ),
                      SizedBox(height: spacingHeight),
                      Text(
                        'Votre panier est vide',
                        style: TextStyle(
                          fontSize: textFontSize,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              final double availableHeight = constraints.maxHeight;

              final double paddingValue = clampDouble(availableWidth * 0.04, 12, 32);
              final double totalFontSize = clampDouble(availableWidth * 0.045, 16, 26);
              final double buttonPaddingVertical = clampDouble(availableHeight * 0.02, 10, 20);
              final double buttonTextFontSize = clampDouble(availableWidth * 0.04, 14, 20);

              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        final item = cart.items[index];
                        return CartItemWidget(item: item);
                      },
                      childCount: cart.items.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(paddingValue),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: totalFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${cart.totalAmount.toStringAsFixed(2)} \$',
                                style: TextStyle(
                                  fontSize: totalFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: availableHeight * 0.02),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _proceedToCheckout(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: buttonPaddingVertical,
                                ),
                                textStyle: TextStyle(
                                  fontSize: buttonTextFontSize,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Passer la commande'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _proceedToCheckout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CheckoutDialog(),
    );
  }
}
