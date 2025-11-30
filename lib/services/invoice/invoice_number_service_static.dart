// lib/services/invoice/invoice_number_service.dart
import 'package:cloud_functions/cloud_functions.dart';

/// Simplified static service for generating invoice numbers
/// 
/// Provides a clean, minimal API for getting the next invoice number.
/// Calls the generateInvoiceNumber Cloud Function transactionally.
class InvoiceNumberService {
  static final HttpsCallable _call =
      FirebaseFunctions.instance.httpsCallable('generateInvoiceNumber');

  /// Get the next invoice number
  /// 
  /// Returns a formatted invoice number like 'AS-000042'
  /// 
  /// Throws Exception if generation fails
  /// 
  /// Example:
  /// ```dart
  /// final invoiceNumber = await InvoiceNumberService.getNextInvoiceNumber();
  /// print(invoiceNumber);  // Output: AS-000042
  /// ```
  static Future<String> getNextInvoiceNumber() async {
    try {
      final res = await _call.call();
      if (res.data != null && res.data['invoiceNumber'] != null) {
        return res.data['invoiceNumber'] as String;
      }
      throw Exception("Failed to generate invoice number");
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to generate invoice number: $e');
    }
  }

  /// Get full result object with counter and timestamp
  /// 
  /// For when you need more than just the formatted number.
  /// 
  /// Example:
  /// ```dart
  /// final result = await InvoiceNumberService.getInvoiceNumberResult();
  /// print(result['invoiceNumber']);  // 'AS-000042'
  /// print(result['counter']);        // 42
  /// print(result['generatedAt']);    // '2025-11-28T15:30:45.123Z'
  /// ```
  static Future<Map<String, dynamic>> getInvoiceNumberResult() async {
    try {
      final res = await _call.call();
      if (res.data != null) {
        return Map<String, dynamic>.from(res.data);
      }
      throw Exception("Failed to generate invoice number");
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to generate invoice number: $e');
    }
  }
}
