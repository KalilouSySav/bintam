import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/admin_orders_tab.dart';
import '../widgets/admin_products_tab.dart';
import '../widgets/admin_users_tab.dart';
import '../widgets/app_drawer.dart';
import '../widgets/nav_button.dart';

class AdminView extends StatefulWidget {
  const AdminView({Key? key}) : super(key: key);

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Vérifier les permissions admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (!auth.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Accès non autorisé',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: _getAppBarHeight(context), // Dynamic app bar height
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade600,
                Colors.deepPurple.shade800,
                Colors.indigo.shade900,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: isDesktop ? null : Builder(
              builder: (context) => Container(
                margin: EdgeInsets.all(_getAppBarPadding(context)), // Dynamic padding
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, color: Colors.white, size: _getIconSize(context)), // Dynamic icon size
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),

                // Navigation boutons à gauche
                NavButton(label: 'Accueil', route: '/', color: Colors.white),
                NavButton(label: 'Catalogue', route: '/catalogue', color: Colors.white),
                NavButton(label: 'Contact', route: '/contact', color: Colors.white),
              ],
            )
                : const Text(
              'Administration',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Icône panier
              Consumer<CartController>(
                builder: (context, cart, child) {
                  return IconButton(
                    color: Colors.white,
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
                    icon: const Icon(Icons.person, color: Colors.white),
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
                          context.go('/');
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
            bottom: PreferredSize(
              preferredSize: _getTabBarHeight(context), // Dynamic TabBar height
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: _getTabBarHorizontalMargin(context), // Dynamic margin
                  vertical: _getTabBarVerticalMargin(context),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: EdgeInsets.symmetric(horizontal: _getIndicatorHorizontalPadding(context)), // Dynamic padding
                  labelColor: Colors.deepPurple.shade700,
                  unselectedLabelColor: Colors.white.withOpacity(0.8),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getTabLabelFontSize(context), // Dynamic font size
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: _getTabLabelFontSize(context), // Dynamic font size
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_rounded, size: _getTabIconSize(context)), // Dynamic icon size
                          SizedBox(width: _getTabIconTextSpacing(context)),
                          Text('Produits'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_rounded, size: _getTabIconSize(context)),
                          SizedBox(width: _getTabIconTextSpacing(context)),
                          Text('Commandes'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_rounded, size: _getTabIconSize(context)),
                          SizedBox(width: _getTabIconTextSpacing(context)),
                          Text('Utilisateurs'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: isDesktop ? null : const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(const AdminProductsTab(), Icons.inventory_2_rounded, context),
            _buildTabContent(const AdminOrdersTab(), Icons.shopping_cart_rounded, context),
            _buildTabContent(const AdminUsersTab(), Icons.people_rounded, context),
          ],
        ),
      ),
    );
  }

  // Helper methods for responsiveness
  Size _getAppBarHeight(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const Size.fromHeight(120); // Standard for small screens
    } else if (screenWidth < 900) {
      return const Size.fromHeight(140); // Slightly taller for medium screens
    } else {
      return const Size.fromHeight(160); // Taller for large screens (e.g., desktop)
    }
  }

  double _getAppBarPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 8 : 16;
  }

  double _getIconSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 24 : 28;
  }

  double _getTitleFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 20 : (screenWidth < 900 ? 24 : 28);
  }

  double _getSubtitleFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 12 : (screenWidth < 900 ? 14 : 16);
  }

  Size _getTabBarHeight(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Size.fromHeight(screenWidth < 600 ? 50 : 60);
  }

  double _getTabBarHorizontalMargin(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 16 : (screenWidth < 900 ? 32 : 64);
  }

  double _getTabBarVerticalMargin(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 8 : 12;
  }

  double _getIndicatorHorizontalPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // This value often needs careful tuning. Adjust based on visual testing.
    return screenWidth < 600 ? -20 : -40;
  }

  double _getTabLabelFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 12 : (screenWidth < 900 ? 14 : 15);
  }

  double _getTabIconSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 14 : (screenWidth < 900 ? 16 : 18);
  }

  double _getTabIconTextSpacing(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600 ? 4 : 6;
  }

  Widget _buildTabContent(Widget child, IconData icon, BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    double margin = screenWidth < 600 ? 8 : (screenWidth < 900 ? 16 : 24);
    double borderRadius = screenWidth < 600 ? 12 : 20;

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}