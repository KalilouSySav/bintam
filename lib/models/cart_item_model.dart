class CartItemModel {
  final String id;
  final String productId;
  final String nom;
  final double prix;
  final String imageUrl;
  int quantite;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.nom,
    required this.prix,
    required this.imageUrl,
    required this.quantite,
  });

  double get sousTotal => prix * quantite;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'nom': nom,
      'prix': prix,
      'imageUrl': imageUrl,
      'quantite': quantite,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      nom: map['nom'] ?? '',
      prix: (map['prix'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantite: map['quantite'] ?? 1,
    );
  }
}