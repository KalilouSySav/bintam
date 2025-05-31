import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseDao<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName;

  BaseDao(this.collectionName);

  CollectionReference get collection => _firestore.collection(collectionName);

  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T entity);

  Future<String> create(T entity) async {
    try {
      final docRef = await collection.add(toMap(entity));
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<T?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id; // injection du document ID
        return fromMap(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<List<T>> getAll() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id; // ajout de l'ID
        return fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de tous les éléments: $e');
    }
  }


  Future<void> update(String id, T entity) async {
    try {
      await collection.doc(id).update(toMap(entity));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}