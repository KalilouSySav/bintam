import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class AuthView extends StatefulWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Authentification' : 'Inscription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildResponsiveBody(context),
    );
  }

  Widget _buildResponsiveBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Définition des breakpoints
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isLargeScreen = constraints.maxWidth >= 1200;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _getHorizontalPadding(isSmallScreen, isMediumScreen),
              vertical: _getVerticalPadding(isSmallScreen),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: _getMaxWidth(isSmallScreen, isMediumScreen, isLargeScreen),
              ),
              child: Card(
                elevation: isSmallScreen ? 4 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(_getCardPadding(isSmallScreen)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Champs de formulaire
                        if (!_isLogin) ...[
                          _buildNameFields(isSmallScreen, isMediumScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                        ],

                        _buildEmailField(),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildPasswordField(),
                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Bouton de soumission
                        _buildSubmitButton(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Bouton de basculement
                        _buildToggleButton(isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          _isLogin ? 'Connexion' : 'Inscription',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameFields(bool isSmallScreen, bool isMediumScreen) {
    // Sur les écrans larges, afficher prénom et nom côte à côte
    if (!isSmallScreen) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _prenomController,
              decoration: _getInputDecoration('Prénom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _nomController,
              decoration: _getInputDecoration('Nom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                return null;
              },
            ),
          ),
        ],
      );
    }

    // Sur les petits écrans, afficher verticalement
    return Column(
      children: [
        TextFormField(
          controller: _prenomController,
          decoration: _getInputDecoration('Prénom'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre prénom';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nomController,
          decoration: _getInputDecoration('Nom'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _getInputDecoration('Email'),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre email';
        }
        if (!value.contains('@')) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _getInputDecoration('Mot de passe'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre mot de passe';
        }
        if (value.length < 6) {
          return 'Au moins 6 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        return SizedBox(
          height: isSmallScreen ? 48 : 56,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
              elevation: 2,
            ),
            child: auth.isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _isLogin ? 'Se connecter' : 'S\'inscrire',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(bool isSmallScreen) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          // Nettoyer les champs lors du basculement
          _emailController.clear();
          _passwordController.clear();
          _nomController.clear();
          _prenomController.clear();
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
      child: Text(
        _isLogin
            ? 'Pas de compte ? Inscrivez-vous'
            : 'Déjà un compte ? Connectez-vous',
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  double _getHorizontalPadding(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) return 16;
    if (isMediumScreen) return 32;
    return 64;
  }

  double _getVerticalPadding(bool isSmallScreen) {
    return isSmallScreen ? 16 : 32;
  }

  double _getMaxWidth(bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    if (isSmallScreen) return double.infinity;
    if (isMediumScreen) return 500;
    return 600;
  }

  double _getCardPadding(bool isSmallScreen) {
    return isSmallScreen ? 20 : 32;
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = context.read<AuthController>();
        bool success;

        if (_isLogin) {
          success = await auth.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else {
          success = await auth.signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nomController.text.trim(),
            _prenomController.text.trim(),
          );
        }

        if (success && mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }
}