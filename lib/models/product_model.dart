class ProductModel {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final String imageUrl;
  final String categorie;
  final int stock;
  final bool estEcologique;
  final DateTime dateAjout;
  final List<String> imagesSecondaires; // Nouveau champ

  ProductModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.imageUrl,
    required this.categorie,
    required this.stock,
    required this.estEcologique,
    required this.dateAjout,
    required this.imagesSecondaires, // Ajout du nouveau champ
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['documentId'] ?? '',
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      prix: (map['prix'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      categorie: map['categorie'] ?? '',
      stock: map['stock'] ?? 0,
      estEcologique: map['estEcologique'] ?? false,
      dateAjout: DateTime.parse(map['dateAjout']),
      imagesSecondaires: List<String>.from(map['imagesSecondaires'] ?? []), // Ajout du nouveau champ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix': prix,
      'imageUrl': imageUrl,
      'categorie': categorie,
      'stock': stock,
      'estEcologique': estEcologique,
      'dateAjout': dateAjout.toIso8601String(),
      'imagesSecondaires': imagesSecondaires, // Ajout du nouveau champ
    };
  }
}
