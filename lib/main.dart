import 'package:bintam/views/admin_view.dart';
import 'package:bintam/views/auth_view.dart';
import 'package:bintam/views/cart_view.dart';
import 'package:bintam/views/catalogue_view.dart';
import 'package:bintam/views/contact_view.dart';
import 'package:bintam/views/home_view.dart';
import 'package:bintam/views/orders_view.dart';
import 'package:bintam/views/phone_auth_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/user_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) => const CatalogueView(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactView(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminView(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersView(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartView(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthView(),
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthView(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => UserController()),
      ],
      child: MaterialApp.router(
        title: 'BintaM',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: _router,
      ),
    );
  }
}
