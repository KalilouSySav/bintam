import 'package:flutter/foundation.dart';
import '../dao/user_dao.dart';
import '../models/user_model.dart';

class UserController extends ChangeNotifier {
  final UserDao _userDao = UserDao();

  UserModel? _user;
  bool _isLoading = false;
  List<UserModel> _users = [];

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  List<UserModel> get users => _users;

  Future<void> loadUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _userDao.getById(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors du chargement de l\'utilisateur: $e');
    }
  }

  Future<String> createUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = await _userDao.create(user);

      _isLoading = false;
      notifyListeners();

      return userId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _userDao.update(user.id, user);
      _user = user;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _userDao.delete(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  Future<void> getUserByEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _userDao.getUserByEmail(email);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la recherche de l\'utilisateur par email: $e');
    }
  }

  Future<void> getUserById(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _userDao.getById(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la récupération de l\'utilisateur par ID: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      _users = await _userDao.getAll();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }
}
