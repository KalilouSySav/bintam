import 'package:flutter/cupertino.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartController extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantite);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.sousTotal);

  void addToCart(ProductModel product, int quantite) {
    final existingIndex = _items.indexWhere(
          (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantite += quantite;
    } else {
      _items.add(CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        nom: product.nom,
        prix: product.prix,
        imageUrl: product.imageUrl,
        quantite: quantite,
      ));
    }

    notifyListeners();
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].quantite = newQuantity;
      notifyListeners();
    }
  }

  void removeFromCart(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}