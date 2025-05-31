import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../utils/whatsapp_service.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({Key? key}) : super(key: key);

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finaliser la commande'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone de livraison',
                  border: OutlineInputBorder(),
                  hintText: '+33700000000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de téléphone';
                  }
                  final phoneRegex = RegExp(r'^\+\d{10,15}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Entrez un numéro valide au format international (+33700000000)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<CartController>(
                builder: (context, cart, child) {
                  return Text(
                    'Total: ${cart.totalAmount.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = context.read<AuthController>();
        final cart = context.read<CartController>();
        final orderController = context.read<OrderController>();

        if (auth.currentUser == null) {
          throw Exception('Vous devez être connecté pour passer commande');
        }

        final userId = auth.currentUser!.id;
        final userName = auth.currentUser!.nom ?? 'Client';

        // Création commande
        await orderController.createOrder(
          userId: userId,
          items: cart.items,
          telephone: _telephoneController.text,
        );

        // Création du message WhatsApp
        final orderDetails = cart.items.map((item) =>
        "- ${item.nom} x${item.quantite}").join("\n");

        final message = """
Bonjour $userName 👋,

Merci pour votre commande sur notre boutique Flutter 🚀

📦 Détails de la commande :
$orderDetails

💰 Total : ${cart.totalAmount.toStringAsFixed(2)} \$

Nous vous contacterons bientôt pour la livraison.
""";

        // Envoi du message WhatsApp
        final success = await WhatsAppService.sendMessage(
          toPhoneNumber: _telephoneController.text,
          message: message,
        );

        cart.clearCart();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Commande passée et message WhatsApp envoyé 🎉'
                  : 'Commande passée, mais message non envoyé 😕'),
              backgroundColor: success ? Colors.green : Colors.orange,
            ),
          );
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la commande: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }
}
