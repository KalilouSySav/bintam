import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../dao/user_dao.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserDao _userDao = UserDao();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationId; // Pour stocker l'ID de vérification du SMS
  int? _resendToken; // Pour le renvoi de SMS
  String _pendingPhoneNumber = "";
  String? _pendingNom; // Nom en attente (pour l'inscription)
  String? _pendingPrenom; // Prénom en attente (pour l'inscription)

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

  // Pour envoyer le code de vérification (connexion)
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier si l'utilisateur existe déjà avec ce numéro
      final existingUser = await _userDao.getUserByEmail(phoneNumber);
      if (existingUser == null) {
        _isLoading = false;
        notifyListeners();
        throw Exception('Aucun compte associé à ce numéro de téléphone');
      }

      _pendingPhoneNumber = phoneNumber;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Vérification automatique (Android uniquement)
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          throw Exception('Erreur de vérification: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        forceResendingToken: _resendToken,
      );

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur d\'envoi du SMS: $e');
    }
  }

  // Pour envoyer le code de vérification (inscription)
  Future<bool> sendPhoneVerificationCodeForSignUp(String phoneNumber, String nom, String prenom) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier si l'utilisateur existe déjà avec ce numéro
      final existingUser = await _userDao.getUserByEmail(phoneNumber);
      if (existingUser != null) {
        _isLoading = false;
        notifyListeners();
        throw Exception('Un compte existe déjà avec ce numéro de téléphone');
      }

      _pendingPhoneNumber = phoneNumber;
      _pendingNom = nom;
      _pendingPrenom = prenom;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Vérification automatique (Android uniquement)
          await _signUpWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          throw Exception('Erreur de vérification: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        forceResendingToken: _resendToken,
      );

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Erreur d\'envoi du SMS: $e');
    }
  }

  // Pour vérifier le code (connexion)
  Future<bool> verifyPhoneCode(String phoneNumber, String code) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_verificationId == null) {
        throw Exception('Code de vérification expiré. Veuillez redemander un code.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final result = await _signInWithPhoneCredential(credential);

      _clearPendingData();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Code invalide: $e');
    }
  }

  // Pour vérifier le code (inscription)
  Future<bool> verifyPhoneCodeForSignUp(String phoneNumber, String code, String nom, String prenom) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_verificationId == null) {
        throw Exception('Code de vérification expiré. Veuillez redemander un code.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final result = await _signUpWithPhoneCredential(credential);

      _clearPendingData();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Code invalide: $e');
    }
  }

  // Méthode privée pour la connexion avec les credentials du téléphone
  Future<bool> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Récupérer l'utilisateur depuis la base de données
        _currentUser = await _userDao.getUserByEmail(_pendingPhoneNumber);

        if (_currentUser == null) {
          // L'utilisateur n'existe pas en base, déconnecter
          await _auth.signOut();
          throw Exception('Aucun compte associé à ce numéro');
        }

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
      rethrow;
    }
  }

  // Méthode privée pour l'inscription avec les credentials du téléphone
  Future<bool> _signUpWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Créer l'utilisateur en base de données
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email:  _pendingPhoneNumber,
          nom: _pendingNom!,
          prenom: _pendingPrenom!,
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
      rethrow;
    }
  }

  // Nettoyer les données temporaires
  void _clearPendingData() {
    _verificationId = null;
    _resendToken = null;
    _pendingPhoneNumber = "";
    _pendingNom = null;
    _pendingPrenom = null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _clearPendingData();
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