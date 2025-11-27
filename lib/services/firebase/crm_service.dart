import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/crm_model.dart';
import '../../data/repositories/crm_repository.dart';

class CrmService {
  final CrmRepository _repo;
  final FirebaseAuth _auth;

  CrmService({CrmRepository? repo, FirebaseAuth? auth})
      : _repo = repo ?? CrmRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  String get currentUid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u.uid;
  }

  Future<String> createContact({
    required String name,
    String email = '',
    String phone = '',
    String company = '',
    String jobTitle = '',
    String notes = '',
    String status = 'lead',
    List<String> tags = const [],
  }) async {
    final uid = currentUid;
    final contact = Contact(
      id: '', // created by Firestore
      userId: uid,
      name: name,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      notes: notes,
      status: "lead",
      tags: tags,
      createdAt: null,
      updatedAt: null,
    );
    return await _repo.createContact(contact);
  }

  Future<void> updateContact(Contact contact) async {
    return await _repo.updateContact(contact);
  }

  Future<void> deleteContact(String contactId) async {
    final uid = currentUid;
    return await _repo.deleteContact(uid, contactId);
  }

  Stream<List<Contact>> streamContacts({String? search}) {
    final uid = currentUid;
    return _repo.streamContacts(uid, search: search);
  }

  Future<Contact?> getContact(String contactId) async {
    final uid = currentUid;
    return await _repo.getContact(uid, contactId);
  }
}