import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_branding.dart';

class BusinessBrandingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get business branding for current user
  Future<BusinessBranding?> getBusinessBranding() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .get();

      if (!doc.exists) return null;
      return BusinessBranding.fromFirestore(doc.data());
    } catch (e) {
      print('Error fetching business branding: $e');
      return null;
    }
  }

  /// Update business branding
  Future<void> updateBusinessBranding(BusinessBranding branding) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .set(branding.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating business branding: $e');
      rethrow;
    }
  }

  /// Update specific branding field
  Future<void> updateBrandingField(String field, dynamic value) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .update({field: value});
    } catch (e) {
      print('Error updating branding field: $e');
      rethrow;
    }
  }

  /// Watch business branding for real-time updates
  Stream<BusinessBranding?> watchBusinessBranding() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('businessBranding')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return BusinessBranding.fromFirestore(doc.data());
    });
  }

  /// Set company details
  Future<void> setCompanyDetails(CompanyDetails details) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .update({'companyDetails': details.toMap()});
    } catch (e) {
      print('Error setting company details: $e');
      rethrow;
    }
  }

  /// Update logo URL
  Future<void> updateLogoUrl(String logoUrl) async {
    await updateBrandingField('logoUrl', logoUrl);
  }

  /// Update colors
  Future<void> updateColors({
    required String primaryColor,
    required String accentColor,
    required String textColor,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .update({
        'primaryColor': primaryColor,
        'accentColor': accentColor,
        'textColor': textColor,
      });
    } catch (e) {
      print('Error updating colors: $e');
      rethrow;
    }
  }

  /// Update signature
  Future<void> updateSignature({
    required bool showSignature,
    String? signatureUrl,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _db
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('businessBranding')
          .update({
        'showSignature': showSignature,
        if (signatureUrl != null) 'signatureUrl': signatureUrl,
      });
    } catch (e) {
      print('Error updating signature: $e');
      rethrow;
    }
  }
}
