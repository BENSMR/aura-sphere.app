import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/invoice_model.dart';

class InvoicePreviewService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate invoice preview PDF with optional customization
  Future<String?> generateInvoicePreview({
    required String invoiceId,
    String templateId = 'default',
    bool includeSignature = true,
    String? watermarkText,
  }) async {
    try {
      final callable =
          _functions.httpsCallable('generateInvoicePreview');

      final response = await callable.call({
        'invoiceId': invoiceId,
        'templateId': templateId,
        'includeSignature': includeSignature,
        if (watermarkText != null) 'watermarkText': watermarkText,
      });

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['pdfUrl'] as String?;
      }

      throw Exception(data['message'] ?? 'Failed to generate preview');
    } catch (e) {
      print('Error generating invoice preview: $e');
      rethrow;
    }
  }

  /// Get all preview URLs for an invoice
  Future<List<Map<String, dynamic>>> getInvoicePreviews(
    String invoiceId,
  ) async {
    try {
      final userId = _db.app.options.projectId;
      
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('previews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching invoice previews: $e');
      return [];
    }
  }

  /// Watch invoice previews in real-time
  Stream<List<Map<String, dynamic>>> watchInvoicePreviews(
    String invoiceId,
  ) {
    try {
      final userId = _db.app.options.projectId;

      return _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('previews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error watching invoice previews: $e');
      return Stream.value([]);
    }
  }

  /// Delete a preview
  Future<void> deletePreview({
    required String invoiceId,
    required String previewId,
  }) async {
    try {
      final userId = _db.app.options.projectId;

      await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('previews')
          .doc(previewId)
          .delete();
    } catch (e) {
      print('Error deleting preview: $e');
      rethrow;
    }
  }

  /// Clean up expired previews
  Future<int> cleanupExpiredPreviews(String invoiceId) async {
    try {
      final userId = _db.app.options.projectId;

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .doc(invoiceId)
          .collection('previews')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up expired previews: $e');
      return 0;
    }
  }

  /// Generate preview with custom branding
  Future<String?> generateCustomBrandingPreview({
    required String invoiceId,
    required Map<String, dynamic> customBranding,
  }) async {
    try {
      // Generate with default template
      final pdfUrl = await generateInvoicePreview(
        invoiceId: invoiceId,
        templateId: customBranding['invoiceTemplateId'] ?? 'default',
        includeSignature: customBranding['showSignature'] ?? true,
        watermarkText: customBranding['watermarkText'],
      );

      return pdfUrl;
    } catch (e) {
      print('Error generating custom branding preview: $e');
      rethrow;
    }
  }

  /// Generate preview with all templates for comparison
  Future<Map<String, String?>> generateAllTemplateVariants(
    String invoiceId,
  ) async {
    try {
      final templates = ['default', 'minimal', 'detailed', 'compact'];
      final results = <String, String?>{};

      for (final template in templates) {
        try {
          final url = await generateInvoicePreview(
            invoiceId: invoiceId,
            templateId: template,
          );
          results[template] = url;
        } catch (e) {
          print('Error generating $template template: $e');
          results[template] = null;
        }
      }

      return results;
    } catch (e) {
      print('Error generating template variants: $e');
      rethrow;
    }
  }
}
