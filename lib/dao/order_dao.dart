import '../models/order_model.dart';
import 'base_dao.dart';

class OrderDao extends BaseDao<OrderModel> {
  OrderDao() : super('orders');

  @override
  OrderModel fromMap(Map<String, dynamic> map) => OrderModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(OrderModel entity) => entity.toMap();

  @override
  Future<OrderModel?> getById(String id) async {
    try {
      final querySnapshot = await collection
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération par ID: $e');
    }
  }

  @override
  Future<void> update(String id, OrderModel entity) async {
    try {
      // First, find the document that has the matching 'id' field
      final querySnapshot = await collection
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update the found document
        await querySnapshot.docs.first.reference.update(toMap(entity));
      } else {
        throw Exception('Aucun document trouvé avec l\'ID: $id');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    try {
      final querySnapshot = await collection
          .where('userId', isEqualTo: userId)
          .orderBy('dateCommande', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }
}
