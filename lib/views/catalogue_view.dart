import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedSortOption = 'default';
  final ScrollController _scrollController = ScrollController();
  double _scaleFactor = 1.0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().loadProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: isDesktop ? 4 : 2,
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
              : const Text('Catalogue'),
          actions: [
            Consumer<CartController>(
              builder: (context, cart, child) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.black),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
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
                      case 'orders':
                        context.go('/orders');
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
                        if (auth.isCust)
                          const PopupMenuItem(
                            value: 'orders',
                            child: Text('Commande'),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        context.read<ProductController>().searchProducts(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Consumer<ProductController>(
                    builder: (context, controller, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: controller.selectedCategory.isEmpty
                              ? null
                              : controller.selectedCategory,
                          hint: const Text('Catégorie'),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSortOption,
                      hint: const Text('Trier par'),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort, color: Colors.grey),
                      items: const [
                        DropdownMenuItem(
                            value: 'default', child: Text('Par défaut')),
                        DropdownMenuItem(
                            value: 'name_asc', child: Text('Nom A-Z')),
                        DropdownMenuItem(
                            value: 'name_desc', child: Text('Nom Z-A')),
                        DropdownMenuItem(
                            value: 'price_asc', child: Text('Prix croissant')),
                        DropdownMenuItem(
                            value: 'price_desc', child: Text('Prix décroissant')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSortOption = value!;
                        });
                        switch (value) {
                          case 'name_asc':
                            context.read<ProductController>().sortProductsByName(ascending: true);
                            break;
                          case 'name_desc':
                            context.read<ProductController>().sortProductsByName(ascending: false);
                            break;
                          case 'price_asc':
                            context.read<ProductController>().sortProductsByPrice(ascending: true);
                            break;
                          case 'price_desc':
                            context.read<ProductController>().sortProductsByPrice(ascending: false);
                            break;
                          default:
                            context.read<ProductController>().loadProducts();
                        }
                      },
                    ),
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
                      double width = constraints.maxWidth;

                      int crossAxisCount = width < 600
                          ? 1 // Mobile view
                          : width < 900
                          ? 2 // Tablet
                          : width < 1200
                          ? 3 // Small desktop
                          : 4; // Large screen

                      return GestureDetector(
                        onScaleUpdate: (details) {
                          setState(() {
                            _scaleFactor = details.scale;
                          });
                        },
                        child: Transform.scale(
                          scale: _scaleFactor,
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(isDesktop ? 24 : 4),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: isDesktop ? 0.7 : 0.8,
                              crossAxisSpacing: isDesktop ? 16 : 8,
                              mainAxisSpacing: isDesktop ? 16 : 8,
                            ),
                            itemCount: controller.products.length,
                            itemBuilder: (BuildContext context, int index) {
                              final product = controller.products[index];
                              return ProductCard(product: product);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
