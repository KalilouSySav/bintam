import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/nav_button.dart';

class ContactView extends StatefulWidget {
  const ContactView({Key? key}) : super(key: key);

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

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
            : const Text('Contact'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildContactForm(),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildContactInfoCard(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactForm(),
          const SizedBox(height: 32),
          _buildContactInfoCard(),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contactez-nous',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Envoyer le message'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nos coordonnées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactInfo(
              Icons.location_on,
              'Adresse',
              '317 Rue Hurteau\nMontréal Québec, Canada',
            ),
            const SizedBox(height: 16),
            _buildContactInfo(
              Icons.phone,
              'Téléphone',
              '(438) 764-9714',
            ),
            const SizedBox(height: 16),
            _buildContactInfo(
              Icons.email,
              'Email',
              'maguiraga2000@live.fr',
            ),
            const SizedBox(height: 16),
            _buildContactInfo(
              Icons.access_time,
              'Horaires',
              'Lundi - Vendredi: 9h - 18h\nSamedi: 10h - 16h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(content),
            ],
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message envoyé avec succès !'),
          backgroundColor: Colors.black,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
