import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dao/user_dao.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserDao _userDao = UserDao();
  User? _user;
  String? _verificationId;
  int? _resendToken;

  // Nouveaux getters pour l'authentification par téléphone
  String? get verificationId => _verificationId;
  bool get isPhoneVerificationInProgress => _verificationId != null;


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

  // Nouvelles méthodes pour l'authentification par téléphone
  Future<void> verifyPhoneNumber(
      String phoneNumber, {
        Function(String)? onCodeSent,
        Function(String)? onError,
        Function()? onCompleted,
      }) async {
    _setLoading(true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Connexion automatique (Android uniquement)
          try {
            await _auth.signInWithCredential(credential);
            _verificationId = null;
            _setLoading(false);
            onCompleted?.call();
          } catch (e) {
            _setLoading(false);
            onError?.call('Erreur de vérification automatique: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          String errorMessage;

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Le numéro de téléphone n\'est pas valide.';
              break;
            case 'too-many-requests':
              errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
              break;
            case 'quota-exceeded':
              errorMessage = 'Quota SMS dépassé. Veuillez réessayer plus tard.';
              break;
            default:
              errorMessage = 'Erreur de vérification: ${e.message}';
          }

          onError?.call(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _setLoading(false);
          onCodeSent?.call('Code envoyé au $phoneNumber');
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          _setLoading(false);
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      _setLoading(false);
      onError?.call('Erreur lors de l\'envoi du SMS: ${e.toString()}');
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('Aucune vérification en cours');
    }

    _setLoading(true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      _verificationId = null;
      _resendToken = null;
      return true;
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Code de vérification invalide.';
            break;
          case 'session-expired':
            errorMessage = 'Session expirée. Veuillez recommencer.';
            break;
          default:
            errorMessage = 'Erreur de vérification: ${e.message}';
        }
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      throw Exception(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendOTP(String phoneNumber) async {
    if (_verificationId == null) {
      throw Exception('Aucune vérification en cours');
    }

    await verifyPhoneNumber(phoneNumber);
  }

  // Lier un numéro de téléphone à un compte existant
  Future<bool> linkPhoneNumber(String phoneNumber, String otp) async {
    if (_user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    _setLoading(true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _user!.linkWithCredential(credential);
      _verificationId = null;
      _resendToken = null;
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la liaison: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Délier un numéro de téléphone
  Future<void> unlinkPhoneNumber() async {
    if (_user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    _setLoading(true);
    try {
      await _user!.unlink(PhoneAuthProvider.PROVIDER_ID);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void cancelPhoneVerification() {
    _verificationId = null;
    _resendToken = null;
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Vérifier si l'utilisateur a un numéro de téléphone lié
  bool get hasPhoneNumber {
    return _user?.providerData.any(
            (info) => info.providerId == PhoneAuthProvider.PROVIDER_ID
    ) ?? false;
  }

  // Obtenir le numéro de téléphone de l'utilisateur
  String? get phoneNumber {
    return _user?.phoneNumber;
  }
}