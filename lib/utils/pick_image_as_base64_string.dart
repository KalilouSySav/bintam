import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Fonction qui compresse une image en réduisant sa qualité et/ou ses dimensions
Uint8List compressImage(Uint8List imageBytes, {
  int quality = 85,
  int? maxWidth,
  int? maxHeight,
}) {
  // Décoder l'image
  img.Image? image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;

  // Redimensionner si nécessaire
  if (maxWidth != null || maxHeight != null) {
    image = img.copyResize(
      image,
      width: maxWidth,
      height: maxHeight,
      maintainAspect: true,
    );
  }

  // Encoder avec compression JPEG
  List<int> compressedBytes = img.encodeJpg(image, quality: quality);
  return Uint8List.fromList(compressedBytes);
}

/// Fonction qui ouvre un sélecteur de fichier pour choisir une ou plusieurs images,
/// lit leur contenu en bytes, les compresse, puis les convertit en strings Base64.
Future<List<String>?> pickImagesAsBase64Strings({
  bool enableCompression = true,
  int compressionQuality = 85,
  int? maxWidth = 1920,
  int? maxHeight = 1080,
}) async {
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
        // Compression de l'image si activée
        if (enableCompression) {
          try {
            fileBytes = compressImage(
              fileBytes,
              quality: compressionQuality,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            );
          } catch (e) {
            // En cas d'erreur de compression, utiliser l'image originale
            debugPrint('Erreur lors de la compression: $e');
          }
        }

        // Encodage en base64
        String base64String = base64Encode(fileBytes as List<int>);
        base64Strings.add(base64String);
      }
    }

    return base64Strings.isNotEmpty ? base64Strings : null;
  }

  // Retourne null si aucun fichier sélectionné ou erreur
  return null;
}

/// Fonction qui ouvre un sélecteur de fichier pour choisir une image,
/// lit son contenu en bytes, la compresse, puis la convertit en string Base64.
Future<String?> pickImageAsBase64String({
  bool enableCompression = true,
  int compressionQuality = 85,
  int? maxWidth = 1920,
  int? maxHeight = 1080,
}) async {
  // Utilise la nouvelle fonction avec la sélection multiple, mais ne prend que la première image
  final images = await pickImagesAsBase64Strings(
    enableCompression: enableCompression,
    compressionQuality: compressionQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  if (images != null && images.isNotEmpty) {
    return images.first;
  }

  // Retourne null si aucun fichier sélectionné ou erreur
  return null;
}

Future<String?> pickImageAndUploadToAWS({
  required String awsBucketUrl, // ex: https://your-bucket-name.s3.amazonaws.com
  String awsFolder = "uploads", // ex: dossier dans le bucket
  bool enableCompression = true,
  int compressionQuality = 85,
  int? maxWidth = 1920,
  int? maxHeight = 1080,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    Uint8List? fileBytes = file.bytes;
    String fileName = path.basename(file.name);

    // Compression
    if (enableCompression && fileBytes != null) {
      try {
        img.Image? image = img.decodeImage(fileBytes);
        if (image != null) {
          if (maxWidth != null || maxHeight != null) {
            image = img.copyResize(image, width: maxWidth, height: maxHeight, maintainAspect: true);
          }
          fileBytes = Uint8List.fromList(img.encodeJpg(image, quality: compressionQuality));
        }
      } catch (e) {
        print('Erreur lors de la compression: $e');
      }
    }

    if (fileBytes != null) {
      final objectKey = '$awsFolder/$fileName';
      final url = '$awsBucketUrl/$objectKey';

      // Upload avec PUT
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'image/jpeg',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        print(url);
        return url;
      } else {
        print('Erreur AWS: ${response.statusCode} - ${response.body}');
      }
    }
  }

  return null;
}

Future<List<String>> pickAndUploadMultipleImagesToAWS({
  required String awsBucketUrl, // ex: https://your-bucket-name.s3.amazonaws.com
  String awsFolder = "uploads",
  bool enableCompression = true,
  int compressionQuality = 85,
  int? maxWidth = 1920,
  int? maxHeight = 1080,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: true,
  );

  List<String> uploadedUrls = [];

  if (result != null && result.files.isNotEmpty) {
    for (var file in result.files) {
      Uint8List? fileBytes = file.bytes;
      String fileName = path.basename(file.name);

      // Compression si activée
      if (enableCompression && fileBytes != null) {
        try {
          img.Image? image = img.decodeImage(fileBytes);
          if (image != null) {
            if (maxWidth != null || maxHeight != null) {
              image = img.copyResize(image, width: maxWidth, height: maxHeight, maintainAspect: true);
            }
            fileBytes = Uint8List.fromList(img.encodeJpg(image, quality: compressionQuality));
          }
        } catch (e) {
          print('Erreur lors de la compression de ${file.name}: $e');
        }
      }

      if (fileBytes != null) {
        final objectKey = '$awsFolder/$fileName';
        final url = '$awsBucketUrl/$objectKey';

        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'image/jpeg',
            // ⚠️ Ne pas inclure 'x-amz-acl' si le bucket a les ACL désactivées
          },
          body: fileBytes,
        );

        if (response.statusCode == 200) {
          uploadedUrls.add(url);
        } else {
          print('Erreur AWS pour $fileName: ${response.statusCode} - ${response.body}');
        }
      }
    }
  }

  return uploadedUrls;
}
