import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service utilitaire pour envoyer un SMS via AWS SNS à travers une API Gateway
class SendSmsService {
  /// L'URL de l'endpoint de l'API Gateway déployée
  final String apiUrl;

  /// Constructeur du service
  SendSmsService({required this.apiUrl});

  /// Envoie un SMS à un numéro international avec le message donné
  ///
  /// - [phoneNumber] doit être au format international : ex. `+15145551234`
  /// - [message] est le contenu du SMS
  ///
  /// Retourne `true` si le message a été envoyé avec succès, sinon lance une exception
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final uri = Uri.parse(apiUrl);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ SMS envoyé. ID: ${data['messageId']}");
      return true;
    } else {
      print("❌ Échec de l'envoi du SMS : ${response.statusCode}");
      print("Message d'erreur : ${response.body}");
      throw Exception("Erreur lors de l'envoi du SMS");
    }
  }
}
