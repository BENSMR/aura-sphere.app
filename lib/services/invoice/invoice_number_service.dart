// lib/services/invoice/invoice_number_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for reading invoice counter and generating formatted invoice numbers.
/// The counter is server-only and incremented atomically by the Cloud Function.
class InvoiceNumberService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the next invoice number for a user.
  /// 
  /// Reads the invoiceCounter from the business profile (read-only for client).
  /// The counter is incremented server-side when invoices are exported.
  /// 
  /// Returns a formatted invoice number like "INV-001234"
  /// Throws if business profile doesn't exist or counter not initialized.
  Future<String> getNextInvoiceNumber(String userId) async {
    try {
      final businessRef = _db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('business');

      final doc = await businessRef.get();

      if (!doc.exists) {
        throw Exception('Business profile not found for user $userId');
      }

      final data = doc.data() as Map<String, dynamic>;
      final counter = (data['invoiceCounter'] ?? 0) as int;

      // Format as INV-XXXXXX (6-digit zero-padded)
      final formattedNumber = 'INV-${counter.toString().padLeft(6, '0')}';

      return formattedNumber;
    } catch (e) {
      throw Exception('Failed to get next invoice number: $e');
    }
  }

  /// Get the current invoice counter value (for display purposes).
  /// This is read-only and shows the count of invoices already exported.
  Future<int> getInvoiceCounter(String userId) async {
    try {
      final businessRef = _db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('business');

      final doc = await businessRef.get();

      if (!doc.exists) {
        return 0; // Default to 0 if business profile doesn't exist
      }

      final data = doc.data() as Map<String, dynamic>;
      return (data['invoiceCounter'] ?? 0) as int;
    } catch (e) {
      throw Exception('Failed to get invoice counter: $e');
    }
  }

  /// Stream invoice counter changes in real-time.
  /// Useful for displaying current counter value in UI.
  Stream<int> watchInvoiceCounter(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('meta')
        .doc('business')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return 0;
          final data = doc.data() as Map<String, dynamic>;
          return (data['invoiceCounter'] ?? 0) as int;
        });
  }

  /// Get all invoice metadata (counter, prefix, etc.).
  /// Useful for invoice creation workflows.
  Future<InvoiceNumberMetadata> getInvoiceMetadata(String userId) async {
    try {
      final businessRef = _db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('business');

      final doc = await businessRef.get();

      if (!doc.exists) {
        throw Exception('Business profile not found for user $userId');
      }

      final data = doc.data() as Map<String, dynamic>;

      return InvoiceNumberMetadata(
        counter: (data['invoiceCounter'] ?? 0) as int,
        prefix: (data['invoicePrefix'] ?? 'INV') as String,
        nextNumber: _formatInvoiceNumber(
          (data['invoiceCounter'] ?? 0) as int,
          (data['invoicePrefix'] ?? 'INV') as String,
        ),
        lastExportedAt:
            data['lastInvoiceExportedAt'] != null
                ? DateTime.parse(data['lastInvoiceExportedAt'] as String)
                : null,
      );
    } catch (e) {
      throw Exception('Failed to get invoice metadata: $e');
    }
  }

  /// Format invoice number with custom prefix.
  /// Example: _formatInvoiceNumber(42, 'INV') returns 'INV-000042'
  static String _formatInvoiceNumber(int counter, String prefix) {
    return '$prefix-${counter.toString().padLeft(6, '0')}';
  }
}

/// Metadata about invoice numbering for a business.
class InvoiceNumberMetadata {
  final int counter;
  final String prefix;
  final String nextNumber;
  final DateTime? lastExportedAt;

  InvoiceNumberMetadata({
    required this.counter,
    required this.prefix,
    required this.nextNumber,
    this.lastExportedAt,
  });

  @override
  String toString() =>
      'InvoiceNumberMetadata(counter: $counter, prefix: $prefix, nextNumber: $nextNumber, lastExportedAt: $lastExportedAt)';
}
