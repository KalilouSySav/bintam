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
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  String _selectedCountryCode = '+33'; // France par défaut
  bool _isOTPSent = false;
  int _resendCountdown = 0;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
    {'code': '+1', 'country': 'États-Unis', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'Royaume-Uni', 'flag': '🇬🇧'},
    {'code': '+49', 'country': 'Allemagne', 'flag': '🇩🇪'},
    {'code': '+34', 'country': 'Espagne', 'flag': '🇪🇸'},
    {'code': '+39', 'country': 'Italie', 'flag': '🇮🇹'},
    {'code': '+91', 'country': 'Inde', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'Chine', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'Japon', 'flag': '🇯🇵'},
    {'code': '+221', 'country': 'Sénégal', 'flag': '🇸🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification par téléphone'),
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
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _getHorizontalPadding(isSmallScreen, isMediumScreen),
              vertical: 16,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: _getMaxWidth(isSmallScreen, isMediumScreen),
              ),
              child: Card(
                elevation: isSmallScreen ? 4 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                  child: Consumer<AuthController>(
                    builder: (context, auth, child) {
                      // Correction: utiliser isPhoneVerificationInProgress au lieu de _isOTPSent
                      if (!_isOTPSent && !auth.isPhoneVerificationInProgress) {
                        return _buildPhoneNumberForm(isSmallScreen, auth);
                      } else {
                        return _buildOTPForm(isSmallScreen, auth);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneNumberForm(bool isSmallScreen, AuthController auth) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Authentification par SMS',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre numéro de téléphone pour recevoir un code de vérification',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Sélecteur de pays
          DropdownButtonFormField<String>(
            value: _selectedCountryCode,
            decoration: _getInputDecoration('Pays'),
            items: _countryCodes.map((country) {
              return DropdownMenuItem<String>(
                value: country['code'],
                child: Row(
                  children: [
                    Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('${country['code']} ${country['country']}'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountryCode = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Champ numéro de téléphone
          TextFormField(
            controller: _phoneController,
            decoration: _getInputDecoration('Numéro de téléphone'),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro de téléphone';
              }
              if (value.length < 6) {
                return 'Numéro trop court';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Bouton envoyer SMS
          SizedBox(
            height: isSmallScreen ? 48 : 56,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Envoyer le code SMS',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lien retour vers authentification email
          TextButton(
            onPressed: () => context.go('/auth'),
            child: const Text(
              'Se connecter avec un email',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm(bool isSmallScreen, AuthController auth) {
    return Form(
      key: _otpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Code de vérification',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez le code à 6 chiffres envoyé au\n$_selectedCountryCode ${_phoneController.text}',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Champ code OTP
          TextFormField(
            controller: _otpController,
            decoration: _getInputDecoration('Code de vérification'),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le code';
              }
              if (value.length != 6) {
                return 'Le code doit contenir 6 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Bouton vérifier
          SizedBox(
            height: isSmallScreen ? 48 : 56,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Vérifier le code',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton renvoyer le code
          TextButton(
            onPressed: _resendCountdown > 0 ? null : _resendOTP,
            child: Text(
              _resendCountdown > 0
                  ? 'Renvoyer le code dans ${_resendCountdown}s'
                  : 'Renvoyer le code',
              style: TextStyle(
                color: _resendCountdown > 0 ? Colors.grey : Colors.blue,
              ),
            ),
          ),

          // Bouton modifier le numéro
          TextButton(
            onPressed: _changePhoneNumber,
            child: const Text(
              'Modifier le numéro de téléphone',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
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

  void _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
      final auth = context.read<AuthController>();

      await auth.verifyPhoneNumber(
        '+1 514-402-0466',
        onCodeSent: (message) {
          setState(() {
            _isOTPSent = true;
          });
          _startResendCountdown();
          _showSnackBar('Code envoyé', Colors.green);
        },
        onError: (error) {
          _showSnackBar(error, Colors.red);
        },
        onCompleted: () {
          // Connexion automatique réussie
          context.go('/');
        },
      );
    }
  }

  void _verifyOTP() async {
    if (_otpFormKey.currentState!.validate()) {
      try {
        final auth = context.read<AuthController>();
        final success = await auth.verifyOTP(_otpController.text);

        if (success && mounted) {
          context.go('/');
        }
      } catch (e) {
        _showSnackBar(e.toString(), Colors.red);
      }
    }
  }

  void _resendOTP() async {
    final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
    final auth = context.read<AuthController>();

    await auth.verifyPhoneNumber(
      phoneNumber,
      onCodeSent: (message) {
        _startResendCountdown();
        _showSnackBar('Code renvoyé', Colors.green);
      },
      onError: (error) {
        _showSnackBar(error, Colors.red);
      },
      onCompleted: () {
        // Connexion automatique réussie
        context.go('/');
      },
    );
  }

  void _changePhoneNumber() {
    setState(() {
      _isOTPSent = false;
      _otpController.clear();
    });
    context.read<AuthController>().cancelPhoneVerification();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  double _getHorizontalPadding(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) return 16;
    if (isMediumScreen) return 32;
    return 64;
  }

  double _getMaxWidth(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) return double.infinity;
    if (isMediumScreen) return 500;
    return 600;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}