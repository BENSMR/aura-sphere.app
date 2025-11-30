import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BusinessService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.uid;
  }

  // Stream the current user's business profile
  Stream<BusinessProfile?> streamBusinessProfile() {
    final uid = _currentUserId;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('business')
        .doc('profile')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return BusinessProfile.fromFirestore(snapshot);
        })
        .handleError((_) => null);
  }

  // Get business profile once
  Future<BusinessProfile?> getBusinessProfile() async {
    final uid = _currentUserId;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('business')
          .doc('profile')
          .get();
      
      if (!doc.exists) return null;
      return BusinessProfile.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // Create a new business profile
  Future<void> createBusinessProfile(BusinessProfile profile) async {
    final uid = _currentUserId;
    try {
      final data = profile.copyWith(userId: uid).toMapForCreate();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('business')
          .doc('profile')
          .set(data);
    } catch (e) {
      rethrow;
    }
  }

  // Update business profile
  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    final uid = _currentUserId;
    try {
      final data = profile.copyWith(userId: uid).toMapForUpdate();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('business')
          .doc('profile')
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Update specific fields
  Future<void> updateBusinessProfileFields(Map<String, dynamic> updates) async {
    final uid = _currentUserId;
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('business')
          .doc('profile')
          .update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete business profile
  Future<void> deleteBusinessProfile() async {
    final uid = _currentUserId;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('business')
          .doc('profile')
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Check if business profile exists
  Future<bool> hasBusinessProfile() async {
    final profile = await getBusinessProfile();
    return profile != null;
  }

  // Update logo URL (after upload to storage)
  Future<void> updateLogoUrl(String logoUrl) async {
    await updateBusinessProfileFields({'logoUrl': logoUrl});
  }

  // Update business status
  Future<void> updateBusinessStatus(String status) async {
    await updateBusinessProfileFields({'status': status});
  }

  // Validate business email is unique (across users)
  Future<bool> isBusinessEmailUnique(String email) async {
    try {
      final query = await _firestore
          .collectionGroup('business')
          .where('businessEmail', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      return true; // Allow if validation fails
    }
  }

  // Validate tax ID is unique (across users)
  Future<bool> isTaxIdUnique(String taxId) async {
    try {
      final query = await _firestore
          .collectionGroup('business')
          .where('taxId', isEqualTo: taxId)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      return true; // Allow if validation fails
    }
  }
}
