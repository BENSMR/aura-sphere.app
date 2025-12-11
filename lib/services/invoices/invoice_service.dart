// lib/services/invoices/invoice_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/invoice_model.dart';

class InvoiceService {
  static final _db = FirebaseFirestore.instance;
  static final HttpsCallable _export = FirebaseFunctions.instance.httpsCallable('exportInvoiceFormats');

  /// Create invoice in Firestore and optionally generate exports by calling cloud function
  /// Returns the callable function response map if generatePdf==true, otherwise returns null.
  static Future<Map<String, dynamic>?> createInvoice(InvoiceModel invoice, {bool generatePdf = false}) async {
    // prepare map
    final map = invoice.toMap();
    // set createdAt server side
    map['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _db.collection('invoices').add(map);
    // update invoice id
    await docRef.update({'id': docRef.id});

    if (generatePdf) {
      // build payload for export function using invoice.toMapForExport() if available
      final payload = invoice.toMapForExport();
      payload['invoiceNumber'] = invoice.invoiceNumber;
      payload['createdAt'] = DateTime.now().toIso8601String();
      payload['dueDate'] = invoice.dueDate?.toIso8601String() ?? DateTime.now().toIso8601String();
      // call function
      final result = await _export.call(payload);
      return Map<String, dynamic>.from(result.data as Map);
    }

    return null;
  }

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open url');
    }
  }
}
