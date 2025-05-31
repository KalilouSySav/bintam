enum UserRole { visiteur, client, admin }

class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final UserRole role;
  final DateTime dateCreation;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.dateCreation,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString() == map['role'],
        orElse: () => UserRole.visiteur,
      ),
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role.toString(),
      'dateCreation': dateCreation.toIso8601String(),
    };
  }
}
