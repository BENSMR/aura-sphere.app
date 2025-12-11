import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_pdf_generator.dart';

class InvoicePdfUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _db = FirebaseFirestore.instance;

  /// Upload a generated PDF to Firebase Storage
  /// Returns the download URL on success
  static Future<String> uploadInvoicePdf(
    String invoiceId,
    Uint8List pdfBytes, {
    String userId = '',
    String? invoiceNumber,
  }) async {
    try {
      // Construct the storage path
      final fileName = invoiceNumber ?? invoiceId;
      final path = userId.isNotEmpty
          ? 'invoices/$userId/$fileName.pdf'
          : 'invoices/$fileName.pdf';

      final ref = _storage.ref(path);

      // Upload the PDF with metadata
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'invoiceId': invoiceId,
          'invoiceNumber': invoiceNumber ?? invoiceId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(pdfBytes, metadata);

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  /// Generate and upload an invoice PDF in one call
  /// Returns the download URL
  static Future<String> generateAndUploadInvoicePdf(
    String invoiceId,
    String userId, {
    required String invoiceNumber,
    required String clientName,
    required String clientEmail,
    required double amount,
    required String currency,
    required DateTime date,
    String? notes,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> business,
  }) async {
    try {
      // Generate PDF bytes
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoiceNumber: invoiceNumber,
        clientName: clientName,
        clientEmail: clientEmail,
        amount: amount,
        currency: currency,
        date: date,
        notes: notes,
        items: items,
        business: business,
      );

      // Upload to storage
      final downloadUrl = await uploadInvoicePdf(
        invoiceId,
        pdfBytes,
        userId: userId,
        invoiceNumber: invoiceNumber,
      );

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to generate and upload PDF: $e');
    }
  }

  /// Save PDF URL reference to Firestore
  static Future<void> savePdfUrlToFirestore(
    String userId,
    String invoiceId,
    String pdfUrl, {
    String? invoiceNumber,
  }) async {
    try {
      await _db.collection('users').doc(userId).collection('invoices').doc(invoiceId).update({
        'pdfUrl': pdfUrl,
        'invoiceNumber': invoiceNumber,
        'pdfUploadedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save PDF URL to Firestore: $e');
    }
  }

  /// Generate, upload, and save PDF reference in one transaction
  static Future<String> generateUploadAndSaveInvoicePdf(
    String invoiceId,
    String userId, {
    required String invoiceNumber,
    required String clientName,
    required String clientEmail,
    required double amount,
    required String currency,
    required DateTime date,
    String? notes,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> business,
  }) async {
    try {
      // Generate and upload PDF
      final pdfUrl = await generateAndUploadInvoicePdf(
        invoiceId,
        userId,
        invoiceNumber: invoiceNumber,
        clientName: clientName,
        clientEmail: clientEmail,
        amount: amount,
        currency: currency,
        date: date,
        notes: notes,
        items: items,
        business: business,
      );

      // Save reference to Firestore
      await savePdfUrlToFirestore(
        userId,
        invoiceId,
        pdfUrl,
        invoiceNumber: invoiceNumber,
      );

      return pdfUrl;
    } catch (e) {
      throw Exception('Failed to generate, upload, and save PDF: $e');
    }
  }

  /// Delete PDF from Storage
  static Future<void> deletePdf(String invoiceId, {String userId = ''}) async {
    try {
      final path = userId.isNotEmpty
          ? 'invoices/$userId/$invoiceId.pdf'
          : 'invoices/$invoiceId.pdf';

      final ref = _storage.ref(path);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete PDF: $e');
    }
  }

  /// Get existing PDF from Storage
  static Future<Uint8List> getPdfBytes(String invoiceId, {String userId = ''}) async {
    try {
      final path = userId.isNotEmpty
          ? 'invoices/$userId/$invoiceId.pdf'
          : 'invoices/$invoiceId.pdf';

      final ref = _storage.ref(path);
      final bytes = await ref.getData();

      if (bytes == null) {
        throw Exception('PDF not found');
      }

      return bytes;
    } catch (e) {
      throw Exception('Failed to get PDF: $e');
    }
  }

  /// Get metadata of uploaded PDF
  static Future<FullMetadata?> getPdfMetadata(String invoiceId, {String userId = ''}) async {
    try {
      final path = userId.isNotEmpty
          ? 'invoices/$userId/$invoiceId.pdf'
          : 'invoices/$invoiceId.pdf';

      final ref = _storage.ref(path);
      final metadata = await ref.getMetadata();

      return metadata;
    } catch (e) {
      throw Exception('Failed to get PDF metadata: $e');
    }
  }

  /// List all invoices PDFs for a user
  static Future<List<String>> listInvoicePdfs(String userId) async {
    try {
      final result = await _storage.ref('invoices/$userId').listAll();
      return result.items.map((item) => item.name).toList();
    } catch (e) {
      throw Exception('Failed to list PDFs: $e');
    }
  }

  /// Batch delete multiple PDFs
  static Future<void> batchDeletePdfs(List<String> invoiceIds, {required String userId}) async {
    try {
      for (final invoiceId in invoiceIds) {
        await deletePdf(invoiceId, userId: userId);
      }
    } catch (e) {
      throw Exception('Failed to batch delete PDFs: $e');
    }
  }

  /// Check if PDF exists in storage
  static Future<bool> pdfExists(String invoiceId, {String userId = ''}) async {
    try {
      final path = userId.isNotEmpty
          ? 'invoices/$userId/$invoiceId.pdf'
          : 'invoices/$invoiceId.pdf';

      final ref = _storage.ref(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
}
