// lib/services/business/business_profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/business_profile.dart';

class BusinessProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DocumentReference businessRef(String userId) =>
      _db.collection('users').doc(userId).collection('meta').doc('business');

  /// Returns a BusinessProfile with defaults when missing
  Future<BusinessProfile> loadProfile(String userId) async {
    final doc = await businessRef(userId).get();
    if (!doc.exists) {
      final defaultProfile = _defaultProfile();
      await saveProfile(userId, defaultProfile.toMap());
      return defaultProfile;
    }
    return BusinessProfile.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Legacy: Get raw document snapshot
  Future<DocumentSnapshot> getBusinessProfile(String userId) {
    return businessRef(userId).get();
  }

  /// Save partial profile (merge)
  Future<void> saveProfile(String userId, Map<String, dynamic> payload) async {
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await businessRef(userId).set(payload, SetOptions(merge: true));
  }

  /// Legacy: Save business profile
  Future<void> saveBusinessProfile(String userId, Map<String, dynamic> payload) async {
    payload['updatedAt'] = FieldValue.serverTimestamp();
    // Note: invoiceCounter is server-only, cannot be set/updated by client
    await businessRef(userId).set(payload, SetOptions(merge: true));
  }

  /// upload logo and return URL
  Future<String> uploadLogo(String userId, File file, {String? fileName}) async {
    final path =
        'users/$userId/meta/business/logo_${fileName ?? DateTime.now().millisecondsSinceEpoch.toString()}.png';
    final ref = _storage.ref().child(path);
    final upload = await ref.putFile(file);
    final url = await upload.ref.getDownloadURL();
    return url;
  }

  /// Delete business profile document
  Future<void> deleteProfile(String userId) async {
    await businessRef(userId).delete();
  }

  BusinessProfile _defaultProfile() {
    return BusinessProfile(
      businessName: '',
      legalName: '',
      taxId: '',
      vatNumber: '',
      address: '',
      city: '',
      postalCode: '',
      logoUrl: '',
      invoicePrefix: 'AURA-',
      documentFooter: '',
      brandColor: '#0A84FF',
      watermarkText: '',
      invoiceTemplate: 'minimal',
      defaultCurrency: 'EUR',
      defaultLanguage: 'en',
      taxSettings: {'country': '', 'vatRate': 0},
      updatedAt: null,
    );
  }
}
