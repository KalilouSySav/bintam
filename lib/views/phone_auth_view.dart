import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class PhoneAuthView extends StatefulWidget {
  const PhoneAuthView({Key? key}) : super(key: key);

  @override
  State<PhoneAuthView> createState() => _PhoneAuthViewState();
}

class _PhoneAuthViewState extends State<PhoneAuthView> {
  bool _isLogin = true;
  bool _isCodeSent = false;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  String _selectedCountryCode = '+1'; // France par défaut
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    if (_resendCountdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
          _startCountdown();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authentification par téléphone'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth'),
        ),
      ),
      body: _buildResponsiveBody(context),
    );
  }

  Widget _buildResponsiveBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isLargeScreen = constraints.maxWidth >= 1200;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _getHorizontalPadding(isSmallScreen, isMediumScreen),
              vertical: _getVerticalPadding(isSmallScreen),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                _getMaxWidth(isSmallScreen, isMediumScreen, isLargeScreen),
              ),
              child: Card(
                elevation: isSmallScreen ? 4 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(isSmallScreen ? 12 : 16),
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
                        if (!_isCodeSent) ...[
                          if (!_isLogin) ...[
                            _buildNameFields(isSmallScreen, isMediumScreen),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                          ],
                          _buildPhoneField(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _buildSendCodeButton(isSmallScreen),
                        ] else ...[
                          _buildCodeField(),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildResendCodeButton(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _buildVerifyButton(isSmallScreen),
                        ],
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        if (!_isCodeSent) _buildToggleButton(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildEmailAuthButton(isSmallScreen),
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
          _isCodeSent
              ? 'Vérification du code'
              : (_isLogin ? 'Connexion' : 'Inscription'),
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          _isCodeSent
              ? 'Entrez le code reçu par SMS'
              : 'Utilisez votre numéro de téléphone',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameFields(bool isSmallScreen, bool isMediumScreen) {
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

  Widget _buildPhoneField(bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              items: [
                DropdownMenuItem(value: '+1', child: Text('+1 🇨🇦')),
                DropdownMenuItem(value: '+223', child: Text('+223 🇲🇱')),
                DropdownMenuItem(value: '+33', child: Text('+33 🇫🇷')),
                DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                DropdownMenuItem(value: '+49', child: Text('+49 🇩🇪')),
                DropdownMenuItem(value: '+31', child: Text('+31 🇳🇱')),
                DropdownMenuItem(value: '+27', child: Text('+27 🇿🇦')),
                DropdownMenuItem(value: '+225', child: Text('+225 🇨🇮')),
                DropdownMenuItem(value: '+86', child: Text('+86 🇨🇳')),
                DropdownMenuItem(value: '+221', child: Text('+221 🇸🇳')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountryCode = value!;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            decoration: _getInputDecoration('Numéro de téléphone'),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro';
              }
              if (value.length < 8) {
                return 'Numéro trop court';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      decoration: _getInputDecoration('Code de vérification'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer le code';
        }
        if (value.length < 6) {
          return 'Code incomplet';
        }
        return null;
      },
    );
  }

  Widget _buildSendCodeButton(bool isSmallScreen) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        return SizedBox(
          height: isSmallScreen ? 48 : 56,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleSendCode,
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
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Envoyer le code SMS',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendCodeButton(bool isSmallScreen) {
    return TextButton(
      onPressed: _resendCountdown > 0 ? null : _handleResendCode,
      child: Text(
        _resendCountdown > 0
            ? 'Renvoyer le code dans ${_resendCountdown}s'
            : 'Renvoyer le code',
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: _resendCountdown > 0 ? Colors.grey : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildVerifyButton(bool isSmallScreen) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        return SizedBox(
          height: isSmallScreen ? 48 : 56,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleVerifyCode,
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
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vérifier le code',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          _phoneController.clear();
          _codeController.clear();
          _nomController.clear();
          _prenomController.clear();
          _isCodeSent = false;
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

  Widget _buildEmailAuthButton(bool isSmallScreen) {
    return TextButton(
      onPressed: () {
        context.go('/auth');
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
      child: Text(
        'Se connecter avec un email',
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.blue,
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  double _getMaxWidth(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    if (isSmallScreen) return double.infinity;
    if (isMediumScreen) return 500;
    return 600;
  }

  double _getCardPadding(bool isSmallScreen) {
    return isSmallScreen ? 20 : 32;
  }

  void _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = context.read<AuthController>();
        final fullPhoneNumber = _selectedCountryCode + _phoneController.text.trim();

        bool success;
        if (_isLogin) {
          success = await auth.sendPhoneVerificationCode(fullPhoneNumber);
        } else {
          success = await auth.sendPhoneVerificationCodeForSignUp(
            fullPhoneNumber,
            _nomController.text.trim(),
            _prenomController.text.trim(),
          );
        }

        if (success && mounted) {
          setState(() {
            _isCodeSent = true;
            _resendCountdown = 60; // 60 secondes avant de pouvoir renvoyer
          });
          _startCountdown();
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

  void _handleResendCode() async {
    try {
      final auth = context.read<AuthController>();
      final fullPhoneNumber = _selectedCountryCode + _phoneController.text.trim();

      bool success;
      if (_isLogin) {
        success = await auth.sendPhoneVerificationCode(fullPhoneNumber);
      } else {
        success = await auth.sendPhoneVerificationCodeForSignUp(
          fullPhoneNumber,
          _nomController.text.trim(),
          _prenomController.text.trim(),
        );
      }

      if (success && mounted) {
        setState(() {
          _resendCountdown = 60;
        });
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Code renvoyé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
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

  void _handleVerifyCode() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = context.read<AuthController>();
        final fullPhoneNumber = _selectedCountryCode + _phoneController.text.trim();

        bool success;
        if (_isLogin) {
          success = await auth.verifyPhoneCode(
            fullPhoneNumber,
            _codeController.text.trim(),
          );
        } else {
          success = await auth.verifyPhoneCodeForSignUp(
            fullPhoneNumber,
            _codeController.text.trim(),
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
    _phoneController.dispose();
    _codeController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }
}