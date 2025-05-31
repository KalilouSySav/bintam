import '../models/product_model.dart';
import 'base_dao.dart';

class ProductDao extends BaseDao<ProductModel> {
  ProductDao() : super('products');

  @override
  ProductModel fromMap(Map<String, dynamic> map) => ProductModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ProductModel entity) => entity.toMap();

  Future<List<ProductModel>> getProductsByCategory(String categorie) async {
    try {
      final querySnapshot = await collection
          .where('categorie', isEqualTo: categorie)
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche par catégorie: $e');
    }
  }

  Future<List<ProductModel>> searchProducts(String searchTerm) async {
    try {
      final querySnapshot = await collection
          .where('nom', isGreaterThanOrEqualTo: searchTerm)
          .where('nom', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
