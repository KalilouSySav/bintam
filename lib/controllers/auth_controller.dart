import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dao/user_dao.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserDao _userDao = UserDao();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isCust => _currentUser?.role == UserRole.client;

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _currentUser = await _userDao.getUserByEmail(email);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<bool> signUp(String email, String password, String nom, String prenom) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          nom: nom,
          prenom: prenom,
          role: UserRole.client,
          dateCreation: DateTime.now(),
        );

        await _userDao.create(newUser);
        _currentUser = newUser;

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void setVisitorMode() {
    _currentUser = UserModel(
      id: 'visiteur',
      email: '',
      nom: 'Visiteur',
      prenom: '',
      role: UserRole.visiteur,
      dateCreation: DateTime.now(),
    );
    notifyListeners();
  }
}