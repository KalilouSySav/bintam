
import 'cart_item_model.dart';

enum OrderStatus { enAttente, confirmee, expediee, livree, annulee }

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double montantTotal;
  final OrderStatus status;
  final DateTime dateCommande;
  final String telephone;


  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.montantTotal,
    required this.status,
    required this.dateCommande,
    required this.telephone,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => CartItemModel.fromMap(item))
          .toList(),
      montantTotal: (map['montantTotal'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.enAttente,
      ),
      dateCommande: DateTime.parse(map['dateCommande']),
      telephone: map['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'montantTotal': montantTotal,
      'status': status.toString(),
      'dateCommande': dateCommande.toIso8601String(),
      'telephone': telephone,
    };
  }
}