import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crm_model.dart';

class CrmRepository {
  final FirebaseFirestore _firestore;

  CrmRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _userContactsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('contacts');

  Future<String> createContact(Contact contact) async {
    final ref = _userContactsRef(contact.userId).doc();
    await ref.set(contact.toMapForCreate());
    return ref.id;
  }

  Future<void> updateContact(Contact contact) async {
    final ref = _userContactsRef(contact.userId).doc(contact.id);
    await ref.update(contact.toMapForUpdate());
  }

  Future<void> deleteContact(String userId, String contactId) async {
    final ref = _userContactsRef(userId).doc(contactId);
    await ref.delete();
  }

  Stream<List<Contact>> streamContacts(String userId, {String? search}) {
    Query q = _userContactsRef(userId).orderBy('name');
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      // basic name prefix search (Firestore can't do "contains" efficiently)
      q = q.where('name', isGreaterThanOrEqualTo: s).where('name', isLessThanOrEqualTo: '$s\uf8ff');
    }
    return q.snapshots().map((snap) => snap.docs.map((d) => Contact.fromFirestore(d)).toList());
  }

  Future<Contact?> getContact(String userId, String contactId) async {
    final doc = await _userContactsRef(userId).doc(contactId).get();
    if (!doc.exists) return null;
    return Contact.fromFirestore(doc);
  }
}