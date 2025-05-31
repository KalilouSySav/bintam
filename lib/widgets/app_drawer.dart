import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Grand logo à gauche
                Image.asset(
                  'images/logo-bintam-1.png',
                  height: 80,
                ),
                const SizedBox(width: 16),
                // Texte à droite
                const Expanded(
                  child: Text(
                    'BintaM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Catalogue'),
            onTap: () => context.go('/catalogue'),
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Contact'),
            onTap: () => context.go('/contact'),
          ),
          const Divider(),
          Consumer<AuthController>(
            builder: (context, auth, child) {
              if (auth.isAdmin) {
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Administration'),
                  onTap: () => context.go('/admin'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
