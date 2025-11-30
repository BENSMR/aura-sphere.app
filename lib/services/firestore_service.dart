import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      Logger.error('Failed to get document', error: e);
      rethrow;
    }
  }

  Future<QuerySnapshot> getCollection(String collection) async {
    try {
      return await _firestore.collection(collection).get();
    } catch (e) {
      Logger.error('Failed to get collection', error: e);
      rethrow;
    }
  }

  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      Logger.error('Failed to set document', error: e);
      rethrow;
    }
  }

  /// Set document using path (e.g., "collection/doc/subcoll/subdoc")
  Future<void> set(String path, Map<String, dynamic> data) async {
    try {
      final parts = path.split('/');
      DocumentReference ref = _firestore.collection(parts[0]).doc(parts[1]);
      for (int i = 2; i < parts.length; i += 2) {
        if (i + 1 < parts.length) {
          ref = ref.collection(parts[i]).doc(parts[i + 1]);
        }
      }
      await ref.set(data);
    } catch (e) {
      Logger.error('Failed to set at path', error: e);
      rethrow;
    }
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      Logger.error('Failed to update document', error: e);
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      Logger.error('Failed to delete document', error: e);
      rethrow;
    }
  }
}
