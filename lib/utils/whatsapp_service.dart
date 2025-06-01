import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service utilitaire pour l'envoi de messages via l'API WhatsApp Business (Meta)
class WhatsAppService {
  static const String phoneNumberId = "";
  static const String accessToken = "";

  /// Envoie un message texte à un numéro donné via l’API WhatsApp Cloud
  static Future<bool> sendMessage({
    required String toPhoneNumber,
    required String message,
  }) async {
    final url = Uri.parse(
      "https://graph.facebook.com/v19.0/$phoneNumberId/messages",
    );

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    final body = jsonEncode({
      "messaging_product": "whatsapp",
      "to": toPhoneNumber,
      "type": "text",
      "text": {
        "preview_url": false,
        "body": message,
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Message envoyé avec succès !");
        return true;
      } else {
        print("❌ Erreur lors de l'envoi: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception: $e");
      return false;
    }
  }
}
