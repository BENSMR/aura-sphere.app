// lib/services/invoice/generate_invoice_number_service.dart
import 'package:cloud_functions/cloud_functions.dart';

/// Service for generating invoice numbers via Cloud Function
/// 
/// Uses transactional server-side logic to ensure:
/// - Atomic read-modify-write operation
/// - No race conditions with concurrent requests
/// - Guaranteed sequential numbering
class GenerateInvoiceNumberService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// Generate the next invoice number atomically
  /// 
  /// Calls Cloud Function which:
  /// 1. Reads current counter from business profile
  /// 2. Increments counter
  /// 3. Updates in single atomic transaction
  /// 4. Returns formatted invoice number
  /// 
  /// Returns example: 'AS-000042'
  /// 
  /// Throws HttpsCallableException on failure
  /// 
  /// Example:
  /// ```dart
  /// final service = GenerateInvoiceNumberService();
  /// final result = await service.generateInvoiceNumber();
  /// print(result.invoiceNumber);  // 'AS-000042'
  /// print(result.counter);         // 42
  /// ```
  Future<InvoiceNumberResult> generateInvoiceNumber() async {
    try {
      final callable = _functions.httpsCallable('generateInvoiceNumber');
      final response = await callable.call({});
      
      final data = response.data as Map<String, dynamic>;
      
      return InvoiceNumberResult(
        invoiceNumber: data['invoiceNumber'] as String,
        counter: data['counter'] as int,
        generatedAt: DateTime.parse(data['generatedAt'] as String),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to generate invoice number: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error generating invoice number: $e');
    }
  }
}

/// Result from generateInvoiceNumber Cloud Function
class InvoiceNumberResult {
  /// Formatted invoice number (e.g., 'AS-000042')
  final String invoiceNumber;

  /// Sequential counter value (e.g., 42)
  final int counter;

  /// Timestamp when generated
  final DateTime generatedAt;

  InvoiceNumberResult({
    required this.invoiceNumber,
    required this.counter,
    required this.generatedAt,
  });

  @override
  String toString() =>
      'InvoiceNumberResult(invoiceNumber: $invoiceNumber, counter: $counter, generatedAt: $generatedAt)';
}
