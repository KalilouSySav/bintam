import 'package:flutter/cupertino.dart';

import '../dao/order_dao.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderController extends ChangeNotifier {
  final OrderDao _orderDao = OrderDao();

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  Future<void> loadOrders([String? userId]) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (userId != null) {
        _orders = await _orderDao.getOrdersByUserId(userId);
      } else {
        _orders = await _orderDao.getAll();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors du chargement des commandes: $e');
    }
  }

  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required String telephone,
  }) async {
    try {
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        items: items,
        montantTotal: items.fold(0, (sum, item) => sum + item.sousTotal),
        status: OrderStatus.enAttente,
        dateCommande: DateTime.now(),
        telephone: telephone,
      );

      final orderId = await _orderDao.create(order);
      await loadOrders(userId);

      return orderId;
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final order = await _orderDao.getById(orderId);
      if (order != null) {
        final updatedOrder = OrderModel(
          id: order.id,
          userId: order.userId,
          items: order.items,
          montantTotal: order.montantTotal,
          status: newStatus,
          dateCommande: order.dateCommande,
          telephone: order.telephone,
        );

        await _orderDao.update(orderId, updatedOrder);
        await loadOrders(order.userId);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }
}
