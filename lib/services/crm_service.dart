import 'firestore_service.dart';
import '../models/crm_model.dart';
import '../config/constants.dart';

class CRMService {
  final FirestoreService _firestore = FirestoreService();

  Future<List<CRMContact>> getContacts(String userId) async {
    final snapshot = await _firestore.getCollection(Constants.firestoreCRMCollection);
    return snapshot.docs.map((doc) => CRMContact.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> addContact(CRMContact contact) async {
    await _firestore.setDocument(
      Constants.firestoreCRMCollection,
      contact.id,
      contact.toJson(),
    );
  }
}
