import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Fonction qui ouvre un sélecteur de fichier pour choisir une image,
/// lit son contenu en bytes, puis le convertit en string Base64.
Future<String?> pickImageAsBase64String() async {
  // Ouverture du sélecteur de fichiers
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true, // Important pour obtenir les bytes
  );

  if (result != null && result.files.isNotEmpty) {
    Uint8List? fileBytes = result.files.first.bytes;
    if (fileBytes != null) {
      // Encodage en base64
      String base64String = base64Encode(fileBytes);
      return base64String;
    }
  }

  // Retourne null si aucun fichier sélectionné ou erreur
  return null;
}
