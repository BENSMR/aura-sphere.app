import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/business_model.dart';

/// Service for handling auto-incrementing invoice numbers
/// Integrates with BusinessProfile to generate unique invoice numbers
/// with custom prefixes and sequential numbering
class InvoiceNumberingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current business profile to access invoice configuration
  Future<BusinessProfile?> _getBusinessProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc('profile')
          .get();

      if (!doc.exists) return null;
      return BusinessProfile.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch business profile: $e');
    }
  }

  /// Generate the next invoice number based on business profile settings
  /// Format: [prefix][number padded to 4 digits]
  /// Example: "AS-0001", "INV-1001", "2024-0042"
  ///
  /// Returns the formatted invoice number
  /// Throws if business profile not found or user not authenticated
  Future<String> generateNextInvoiceNumber() async {
    final business = await _getBusinessProfile();

    if (business == null) {
      throw Exception('Business profile not found');
    }

    return _formatInvoiceNumber(
      business.invoicePrefix,
      business.invoiceNextNumber,
    );
  }

  /// Generate invoice number from DocumentSnapshot (for direct Firestore access)
  /// Useful when you already have the business doc loaded
  static String generateInvoiceNumberFromSnapshot(
    DocumentSnapshot business,
  ) {
    final prefix = business['invoicePrefix'] as String? ?? 'INV-';
    final nextNumber = business['invoiceNextNumber'] as int? ?? 1;
    return _formatInvoiceNumber(prefix, nextNumber);
  }

  /// Format invoice number with prefix and zero-padded number
  static String _formatInvoiceNumber(String prefix, int number) {
    return '$prefix${number.toString().padLeft(4, '0')}';
  }

  /// Increment the invoice number after a successful invoice creation
  /// This should be called AFTER the invoice is successfully saved to Firestore
  ///
  /// Parameters:
  ///   - businessUserId: The user ID of the business owner
  ///
  /// Returns: The new invoice number that was incremented to
  /// Throws if update fails
  Future<int> incrementInvoiceNumber({String? businessUserId}) async {
    final userId = businessUserId ?? _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final businessRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc('profile');

      // Increment using server-side transaction for consistency
      final newNumber = await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(businessRef);
        if (!doc.exists) {
          throw Exception('Business profile not found');
        }

        final currentNumber = (doc['invoiceNextNumber'] as int?) ?? 1;
        final newNumber = currentNumber + 1;

        transaction.update(businessRef, {
          'invoiceNextNumber': newNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return newNumber;
      });

      return newNumber;
    } catch (e) {
      throw Exception('Failed to increment invoice number: $e');
    }
  }

  /// Get the current invoice number without incrementing
  /// Useful for displaying the next invoice number to the user
  Future<int> getCurrentInvoiceNumber() async {
    final business = await _getBusinessProfile();
    if (business == null) {
      throw Exception('Business profile not found');
    }
    return business.invoiceNextNumber;
  }

  /// Reset invoice number to a specific value
  /// USE WITH CAUTION: This should only be done during onboarding or admin operations
  /// Previous invoice numbers should never be reused
  Future<void> resetInvoiceNumber(int newNumber) async {
    if (newNumber < 1) {
      throw Exception('Invoice number must be greater than 0');
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business')
          .doc('profile')
          .update({
            'invoiceNextNumber': newNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to reset invoice number: $e');
    }
  }

  /// Get invoice number with custom prefix (without using business profile)
  /// Useful for testing or temporary overrides
  /// Parameters:
  ///   - prefix: Custom prefix (e.g., "INV-", "AS-")
  ///   - number: Invoice number to format
  ///
  /// Returns: Formatted invoice number
  static String getFormattedNumber({
    String prefix = 'INV-',
    int number = 1,
  }) {
    if (number < 0) {
      throw Exception('Invoice number cannot be negative');
    }
    return _formatInvoiceNumber(prefix, number);
  }

  /// Get the last issued invoice number
  /// Useful for display purposes or for validation
  Future<int> getLastIssuedInvoiceNumber() async {
    final current = await getCurrentInvoiceNumber();
    return current > 1 ? current - 1 : 0;
  }

  /// Validate if an invoice number format is correct
  /// Returns true if the format matches expected pattern
  static bool isValidInvoiceNumberFormat(String invoiceNumber) {
    if (invoiceNumber.isEmpty) return false;

    // Basic check: should have at least a prefix and 4-digit number
    // Examples: "INV-0001", "AS-0042", "2024-0001"
    final pattern = RegExp(r'^[A-Z0-9\-]+\d{4}$');
    return pattern.hasMatch(invoiceNumber);
  }

  /// Get next invoice number with detailed info (useful for UI display)
  /// Returns a map with formatted number and next number value
  Future<Map<String, dynamic>> getNextInvoiceInfo() async {
    final business = await _getBusinessProfile();
    if (business == null) {
      throw Exception('Business profile not found');
    }

    final formattedNumber = _formatInvoiceNumber(
      business.invoicePrefix,
      business.invoiceNextNumber,
    );

    return {
      'formattedNumber': formattedNumber,
      'prefix': business.invoicePrefix,
      'nextNumber': business.invoiceNextNumber,
      'lastNumber': business.invoiceNextNumber > 1
          ? business.invoiceNextNumber - 1
          : 0,
      'lastFormattedNumber': business.invoiceNextNumber > 1
          ? _formatInvoiceNumber(
              business.invoicePrefix,
              business.invoiceNextNumber - 1,
            )
          : null,
    };
  }

  /// Batch generate multiple invoice numbers (for preview/validation)
  /// DOES NOT increment the counter
  /// Parameters:
  ///   - count: How many invoice numbers to generate
  ///
  /// Returns: List of formatted invoice numbers
  Future<List<String>> generateMultipleInvoiceNumbers(int count) async {
    if (count < 1 || count > 100) {
      throw Exception('Count must be between 1 and 100');
    }

    final business = await _getBusinessProfile();
    if (business == null) {
      throw Exception('Business profile not found');
    }

    final numbers = <String>[];
    for (int i = 0; i < count; i++) {
      numbers.add(_formatInvoiceNumber(
        business.invoicePrefix,
        business.invoiceNextNumber + i,
      ));
    }
    return numbers;
  }

  /// Check invoice number sequence integrity
  /// Ensures no gaps in the sequence (except the first one)
  /// Useful for audit and compliance purposes
  ///
  /// Returns: true if sequence is valid, false if there are gaps
  Future<bool> validateInvoiceSequence() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .orderBy('invoiceNumber', descending: true)
          .limit(100) // Check last 100 invoices
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      // Get all invoice numbers from documents
      final invoiceNumbers = querySnapshot.docs
          .map((doc) => doc['invoiceNumber'] as int?)
          .whereType<int>()
          .toList();

      if (invoiceNumbers.isEmpty) return true;

      // Check if there are any gaps
      invoiceNumbers.sort((a, b) => b.compareTo(a));

      for (int i = 1; i < invoiceNumbers.length; i++) {
        if (invoiceNumbers[i] != invoiceNumbers[i - 1] - 1) {
          // Gap detected
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
