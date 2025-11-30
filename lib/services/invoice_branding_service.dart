import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';

/// Invoice Branding Service
/// 
/// Manages invoice appearance customization:
/// - Invoice number prefix and sequence management
/// - Watermark configuration
/// - Document footer customization
/// - Signature and stamp management
class InvoiceBrandingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InvoiceBrandingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current branding settings
  Future<Map<String, dynamic>?> getBrandingSettings(String profileId) async {
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

      return doc.data();
    } catch (e) {
      Logger.error('Error fetching branding settings: $e');
      return null;
    }
  }

  /// Update invoice prefix
  Future<void> updateInvoicePrefix(String profileId, String prefix) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (prefix.trim().isEmpty) {
      throw Exception('Prefix cannot be empty');
    }

    if (prefix.length > 10) {
      throw Exception('Prefix too long (max 10 characters)');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update({
            'invoicePrefix': prefix.trim().toUpperCase(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Logger.info('Invoice prefix updated: $prefix');
    } catch (e) {
      Logger.error('Error updating invoice prefix: $e');
      rethrow;
    }
  }

  /// Update watermark text
  Future<void> updateWatermark(String profileId, String? watermarkText) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (watermarkText != null && watermarkText.length > 100) {
      throw Exception('Watermark too long (max 100 characters)');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update({
            'watermarkText': watermarkText,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Logger.info('Watermark updated');
    } catch (e) {
      Logger.error('Error updating watermark: $e');
      rethrow;
    }
  }

  /// Update document footer
  Future<void> updateDocumentFooter(String profileId, String? footerText) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (footerText != null && footerText.length > 500) {
      throw Exception('Footer too long (max 500 characters)');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update({
            'documentFooter': footerText,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Logger.info('Document footer updated');
    } catch (e) {
      Logger.error('Error updating document footer: $e');
      rethrow;
    }
  }

  /// Update digital signature URL
  Future<void> updateSignatureUrl(String profileId, String? signatureUrl) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update({
            'signatureUrl': signatureUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Logger.info('Signature URL updated');
    } catch (e) {
      Logger.error('Error updating signature URL: $e');
      rethrow;
    }
  }

  /// Update stamp URL
  Future<void> updateStampUrl(String profileId, String? stampUrl) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .update({
            'stampUrl': stampUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Logger.info('Stamp URL updated');
    } catch (e) {
      Logger.error('Error updating stamp URL: $e');
      rethrow;
    }
  }

  /// Validate invoice number format
  bool validateInvoiceNumberFormat(
    String invoiceNumber, {
    String prefix = 'INV',
  }) {
    final pattern = RegExp('^$prefix-\\d{4,}\$');
    return pattern.hasMatch(invoiceNumber);
  }

  /// Get next invoice number with formatted prefix
  Future<String> getFormattedInvoiceNumber(String profileId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc(profileId)
          .get();

      if (!doc.exists) {
        throw Exception('Business profile not found');
      }

      final prefix = doc['invoicePrefix'] ?? 'INV';
      final nextNumber = doc['invoiceNextNumber'] ?? 1;

      return '$prefix-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      Logger.error('Error getting formatted invoice number: $e');
      rethrow;
    }
  }

  /// Stream branding settings updates
  Stream<Map<String, dynamic>?> brandingStream(String profileId) {
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
          return snapshot.data();
        });
  }
}
