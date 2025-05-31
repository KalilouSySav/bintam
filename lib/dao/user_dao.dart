
import '../models/user_model.dart';
import 'base_dao.dart';

class UserDao extends BaseDao<UserModel> {
  UserDao() : super('users');

  @override
  UserModel fromMap(Map<String, dynamic> map) => UserModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(UserModel entity) => entity.toMap();

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await collection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la recherche par email: $e');
    }
  }
}
