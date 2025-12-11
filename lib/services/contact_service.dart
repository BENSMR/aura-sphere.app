import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';

/// Service for managing contacts in the finance module
/// 
/// Handles CRUD operations for contacts at users/{uid}/contacts/{contactId}
class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  /// Get a contact by ID
  Future<Contact?> getContact(String contactId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contactId)
          .get();

      if (!doc.exists) return null;
      return Contact.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting contact: $e');
      return null;
    }
  }

  /// Get all contacts for current user
  Future<List<Contact>> getContacts({
    String? type,
    bool? isActive,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts') as Query;

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      final snap = await query
          .orderBy('name')
          .get();

      return snap.docs.map((doc) => Contact.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error getting contacts: $e');
      return [];
    }
  }

  /// Get customers only
  Future<List<Contact>> getCustomers() async {
    return getContacts(type: 'customer', isActive: true);
  }

  /// Get suppliers only
  Future<List<Contact>> getSuppliers() async {
    return getContacts(type: 'supplier', isActive: true);
  }

  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    try {
      if (query.isEmpty) return getContacts();

      final snap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();

      return snap.docs.map((doc) => Contact.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error searching contacts: $e');
      return [];
    }
  }

  /// Create a new contact
  Future<String> createContact({
    required String name,
    required String email,
    String? phone,
    required String country,
    String? currency,
    required bool isBusiness,
    String? vatNumber,
    String? taxId,
    String? companyName,
    String? address,
    String? city,
    String? postalCode,
    String? contactPerson,
    String? contactPersonEmail,
    String? contactPersonPhone,
    String type = 'customer',
    bool isActive = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final contact = Contact(
        id: _firestore
            .collection('users')
            .doc(_currentUid)
            .collection('contacts')
            .doc()
            .id,
        uid: _currentUid,
        name: name,
        email: email,
        phone: phone,
        country: country.toUpperCase(),
        currency: currency?.toUpperCase(),
        isBusiness: isBusiness,
        vatNumber: vatNumber,
        taxId: taxId,
        companyName: companyName,
        address: address,
        city: city,
        postalCode: postalCode,
        contactPerson: contactPerson,
        contactPersonEmail: contactPersonEmail,
        contactPersonPhone: contactPersonPhone,
        type: type,
        isActive: isActive,
        metadata: metadata,
      );

      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contact.id)
          .set(contact.toFirestore());

      print('✅ Contact created: ${contact.id}');
      return contact.id;
    } catch (e) {
      print('❌ Error creating contact: $e');
      rethrow;
    }
  }

  /// Update a contact
  Future<void> updateContact(Contact contact) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contact.id)
          .update(contact.copyWith(updatedAt: DateTime.now()).toFirestore());

      print('✅ Contact updated: ${contact.id}');
    } catch (e) {
      print('❌ Error updating contact: $e');
      rethrow;
    }
  }

  /// Update specific fields of a contact
  Future<void> updateContactFields(String contactId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates)
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contactId)
          .update(updateData);

      print('✅ Contact fields updated: $contactId');
    } catch (e) {
      print('❌ Error updating contact fields: $e');
      rethrow;
    }
  }

  /// Deactivate a contact
  Future<void> deactivateContact(String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contactId)
          .update({'isActive': false});

      print('✅ Contact deactivated: $contactId');
    } catch (e) {
      print('❌ Error deactivating contact: $e');
      rethrow;
    }
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .doc(contactId)
          .delete();

      print('✅ Contact deleted: $contactId');
    } catch (e) {
      print('❌ Error deleting contact: $e');
      rethrow;
    }
  }

  /// Stream of all active contacts (real-time)
  Stream<List<Contact>> watchContacts({String? type}) {
    var query = _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('contacts')
        .where('isActive', isEqualTo: true) as Query;

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Contact.fromFirestore(doc)).toList())
        .handleError((err) {
      print('❌ Error watching contacts: $err');
      return <Contact>[];
    });
  }

  /// Validate email format (basic)
  bool isValidEmail(String email) {
    return email.contains('@') && email.length > 5;
  }

  /// Check if email exists for another contact
  Future<bool> emailExists(String email, {String? excludeContactId}) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .where('email', isEqualTo: email);

      if (excludeContactId != null) {
        final all = await query.get();
        return all.docs.any((doc) => doc.id != excludeContactId);
      }

      final snap = await query.limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      print('⚠️ Error checking email uniqueness: $e');
      return false;
    }
  }

  /// Get contact count by type
  Future<Map<String, int>> getContactStats() async {
    try {
      final total = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .count()
          .get();

      final customers = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .where('type', isEqualTo: 'customer')
          .count()
          .get();

      final suppliers = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('contacts')
          .where('type', isEqualTo: 'supplier')
          .count()
          .get();

      return {
        'total': total.count ?? 0,
        'customers': customers.count ?? 0,
        'suppliers': suppliers.count ?? 0,
      };
    } catch (e) {
      print('❌ Error getting contact stats: $e');
      return {'total': 0, 'customers': 0, 'suppliers': 0};
    }
  }
}
