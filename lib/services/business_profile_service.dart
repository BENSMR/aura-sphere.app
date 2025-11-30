import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/business_model.dart';
import '../core/utils/logger.dart';

/// Business Profile Service
/// 
/// Manages all business profile operations:
/// - Create, read, update, delete business profiles
/// - Handle profile validation
/// - Manage profile streams for real-time updates
class BusinessProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BusinessProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new business profile
  /// Returns the document ID of the created profile
  Future<String> createProfile(BusinessProfile profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .add(profile.toMapForCreate());

      Logger.info('Business profile created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.error('Error creating profile: $e');
      rethrow;
    }
  }

  /// Get business profile by ID
  Future<BusinessProfile?> getProfile(String profileId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .get();

      if (!doc.exists) return null;

      return BusinessProfile.fromFirestore(doc);
    } catch (e) {
      Logger.error('Error fetching profile: $e');
      return null;
    }
  }

  /// Update business profile
  Future<void> updateProfile(String profileId, BusinessProfile profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (profileId.trim().isEmpty) {
      throw Exception('Profile ID is required');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update(profile.toMapForUpdate());

      Logger.info('Business profile updated: $profileId');
    } catch (e) {
      Logger.error('Error updating profile: $e');
      rethrow;
    }
  }

  /// Delete business profile
  Future<void> deleteProfile(String profileId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (profileId.trim().isEmpty) {
      throw Exception('Profile ID is required');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .delete();

      Logger.info('Business profile deleted: $profileId');
    } catch (e) {
      Logger.error('Error deleting profile: $e');
      rethrow;
    }
  }

  /// Validate business profile
  /// Returns map of validation errors (empty if valid)
  Map<String, String> validateProfile(BusinessProfile profile) {
    final errors = <String, String>{};

    // Required fields
    if (profile.businessName.trim().isEmpty) {
      errors['businessName'] = 'Business name is required';
    }

    if (profile.businessType.trim().isEmpty) {
      errors['businessType'] = 'Business type is required';
    }

    if (profile.industry.trim().isEmpty) {
      errors['industry'] = 'Industry is required';
    }

    if (profile.businessEmail.trim().isEmpty) {
      errors['businessEmail'] = 'Business email is required';
    } else if (!_isValidEmail(profile.businessEmail)) {
      errors['businessEmail'] = 'Invalid email format';
    }

    // Phone validation (optional but if provided, must be valid)
    if (profile.businessPhone.isNotEmpty &&
        !_isValidPhone(profile.businessPhone)) {
      errors['businessPhone'] = 'Invalid phone format';
    }

    // Website validation (optional but if provided, must be valid)
    if (profile.website.isNotEmpty && !_isValidUrl(profile.website)) {
      errors['website'] = 'Invalid website URL';
    }

    // Tax ID
    if (profile.taxId.trim().isEmpty) {
      errors['taxId'] = 'Tax ID is required';
    }

    return errors;
  }

  /// Stream business profile updates
  Stream<BusinessProfile?> profileStream(String profileId) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('business')
        .doc(profileId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return BusinessProfile.fromFirestore(snapshot);
        });
  }

  /// Get all business profiles for current user
  Future<List<BusinessProfile>> getAllProfiles() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .get();

      return querySnapshot.docs
          .map((doc) => BusinessProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Error fetching all profiles: $e');
      return [];
    }
  }

  /// Helper: Validate email format
  bool _isValidEmail(String email) {
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  /// Helper: Validate phone format (basic)
  bool _isValidPhone(String phone) {
    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    // Check if it's at least 10 digits
    return cleaned.replaceAll(RegExp(r'\D'), '').length >= 10;
  }

  /// Helper: Validate URL format
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.contains('.');
    } catch (e) {
      return false;
    }
  }
}
