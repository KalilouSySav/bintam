import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/nav_button.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
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
          : const Text('Accueil'),
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
                    if(auth.isCust)
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
      body: CustomScrollView(
        slivers: [
          // Hero Section avec adaptation responsive
          SliverToBoxAdapter(
            child: Container(
              height: isDesktop ? 500 : (isTablet ? 450 : 350),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.lightBlueAccent],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : (isTablet ? 32 : 16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bienvenue sur BintaM',
                        style: TextStyle(
                          fontSize: isDesktop ? 48 : (isTablet ? 36 : 28),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre marketplace local',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : (isTablet ? 20 : 16),
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isDesktop ? 48 : 32),
                      ElevatedButton(
                        onPressed: () => context.go('/catalogue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 48 : (isTablet ? 40 : 32),
                            vertical: isDesktop ? 20 : 16,
                          ),
                          textStyle: TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Découvrir nos produits'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Section des fonctionnalités avec layout adaptatif
          SliverPadding(
            padding: EdgeInsets.all(isDesktop ? 64 : (isTablet ? 48 : 24)),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                    'Pourquoi choisir BintaM ?',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : (isTablet ? 28 : 24),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 48 : 32),

                  // Layout adaptatif pour les cartes de fonctionnalités
                  if (isDesktop)
                  // Desktop : 3 colonnes horizontales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            Icons.currency_exchange,
                            'Économique',
                            'Produits offerts dans des prix concurrenciels',
                            isDesktop: true,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildFeatureCard(
                            Icons.local_shipping,
                            'Livraison rapide',
                            'Expédition sous 24h',
                            isDesktop: true,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildFeatureCard(
                            Icons.verified_user,
                            'Qualité garantie',
                            'Produits certifiés et testés',
                            isDesktop: true,
                          ),
                        ),
                      ],
                    )
                  else if (isTablet)
                  // Tablette : 2 colonnes avec wrap
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: (screenWidth - 96) / 2,
                          child: _buildFeatureCard(
                            Icons.currency_exchange,
                            'Économique',
                            'Produits offerts dans des prix concurrenciels',
                            isTablet: true,
                          ),
                        ),
                        SizedBox(
                          width: (screenWidth - 96) / 2,
                          child: _buildFeatureCard(
                            Icons.local_shipping,
                            'Livraison rapide',
                            'Expédition sous 24h',
                            isTablet: true,
                          ),
                        ),
                        SizedBox(
                          width: (screenWidth - 96),
                          child: _buildFeatureCard(
                            Icons.verified_user,
                            'Qualité garantie',
                            'Produits certifiés et testés',
                            isTablet: true,
                          ),
                        ),
                      ],
                    )
                  else
                  // Mobile : 1 colonne verticale
                    Column(
                      children: [
                        _buildFeatureCard(
                          Icons.currency_exchange,
                          'Économique',
                          'Produits offerts dans des prix concurrenciels',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          Icons.local_shipping,
                          'Livraison rapide',
                          'Expédition sous 24h',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          Icons.verified_user,
                          'Qualité garantie',
                          'Produits certifiés et testés',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon,
      String title,
      String description, {
        bool isDesktop = false,
        bool isTablet = false,
      }) {
    return Container(
      width: isDesktop ? null : (isTablet ? null : double.infinity),
      padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: isDesktop ? 8 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isDesktop ? 56 : (isTablet ? 52 : 48),
            color: Colors.black,
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}