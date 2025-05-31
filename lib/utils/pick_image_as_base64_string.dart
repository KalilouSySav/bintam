import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Fonction qui ouvre un sélecteur de fichier pour choisir une ou plusieurs images,
/// lit leur contenu en bytes, puis les convertit en strings Base64.
Future<List<String>?> pickImagesAsBase64Strings() async {
  // Ouverture du sélecteur de fichiers pour permettre la sélection multiple
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true, // Important pour obtenir les bytes
    allowMultiple: true, // Permet la sélection de plusieurs fichiers
  );

  if (result != null && result.files.isNotEmpty) {
    List<String> base64Strings = [];
    for (var file in result.files) {
      Uint8List? fileBytes = file.bytes;
      if (fileBytes != null) {
        // Encodage en base64
        String base64String = base64Encode(fileBytes);
        base64Strings.add(base64String);
      }
    }
    return base64Strings.isNotEmpty ? base64Strings : null;
  }

  // Retourne null si aucun fichier sélectionné ou erreur
  return null;
}

/// Fonction qui ouvre un sélecteur de fichier pour choisir une image,
/// lit son contenu en bytes, puis le convertit en string Base64.
Future<String?> pickImageAsBase64String() async {
  // Utilise la nouvelle fonction avec la sélection multiple, mais ne prend que la première image
  final images = await pickImagesAsBase64Strings();
  if (images != null && images.isNotEmpty) {
    return images.first;
  }

  // Retourne null si aucun fichier sélectionné ou erreur
  return null;
}
