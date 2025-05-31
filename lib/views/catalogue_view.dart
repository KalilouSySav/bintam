import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/nav_button.dart';
import '../widgets/product_card.dart';

class CatalogueView extends StatefulWidget {
  const CatalogueView({Key? key}) : super(key: key);

  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().loadProducts();
    });
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
            // Logo
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

            // Navigation boutons à gauche
            NavButton(label: 'Accueil', route: '/'),
            NavButton(label: 'Catalogue', route: '/catalogue'),
            NavButton(label: 'Contact', route: '/contact'),
          ],
        )
            : const Text('Catalogue'),
        actions: [
          // Icône panier
          Consumer<CartController>(
            builder: (context, cart, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.go('/cart'),
              );
            },
          ),

          // Menu utilisateur
          Consumer<AuthController>(
            builder: (context, auth, child) {
              return PopupMenuButton<String>(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      context.read<ProductController>().searchProducts(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Consumer<ProductController>(
                  builder: (context, controller, child) {
                    return DropdownButton<String>(
                      value: controller.selectedCategory.isEmpty
                          ? null
                          : controller.selectedCategory,
                      hint: const Text('Catégorie'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Toutes')),
                        DropdownMenuItem(
                            value: 'alimentation', child: Text('Alimentation')),
                        DropdownMenuItem(
                            value: 'automobile', child: Text('Automobile')),
                        DropdownMenuItem(
                            value: 'maison', child: Text('Maison')),
                        DropdownMenuItem(value: 'mode', child: Text('Mode')),
                      ],
                      onChanged: (value) {
                        controller.filterByCategory(value ?? '');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ProductController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.products.isEmpty) {
                  return const Center(
                    child: Text('Aucun produit trouvé'),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200
                        ? 4
                        : constraints.maxWidth > 800
                        ? 3
                        : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: controller.products.length,
                      itemBuilder: (BuildContext context, int index) {
                        final product = controller.products[index];
                        return ProductCard(product: product);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
