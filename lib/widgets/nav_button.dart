import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavButton extends StatelessWidget {
  final String label;
  final String route;
  final Color color;

  const NavButton({
    Key? key,
    required this.label,
    required this.route,
    this.color = Colors.black, // valeur par défaut
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(label),
    );
  }
}
