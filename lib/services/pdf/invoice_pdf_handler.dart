import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/invoice_model.dart';
import 'invoice_pdf_service.dart';

class InvoicePdfHandler {
  /// Generate and print invoice PDF
  static Future<void> printInvoice(InvoiceModel invoice) async {
    try {
      final pdfDoc = await InvoicePdfService.generate(invoice);
      await Printing.layoutPdf(
        onLayout: (_) => pdfDoc.save(),
        name: invoice.invoiceNumber ?? 'invoice',
      );
    } catch (e) {
      throw InvoicePdfException('Failed to print invoice: $e');
    }
  }

  /// Generate and share invoice PDF via email/messaging
  static Future<void> shareInvoice(InvoiceModel invoice) async {
    try {
      final pdfDoc = await InvoicePdfService.generate(invoice);
      await Printing.sharePdf(
        bytes: await pdfDoc.save(),
        filename: '${invoice.invoiceNumber ?? 'invoice'}.pdf',
      );
    } catch (e) {
      throw InvoicePdfException('Failed to share invoice: $e');
    }
  }

  /// Save invoice PDF to device storage
  static Future<String> saveToFile(InvoiceModel invoice) async {
    try {
      final pdfDoc = await InvoicePdfService.generate(invoice);
      final bytes = await pdfDoc.save();

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${dir.path}/invoices');

      // Create invoices folder if not exists
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      // Save file
      final fileName = '${invoice.invoiceNumber ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${invoicesDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw InvoicePdfException('Failed to save invoice to file: $e');
    }
  }

  /// Get all saved invoice PDFs
  static Future<List<File>> getSavedInvoices() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${dir.path}/invoices');

      if (!await invoicesDir.exists()) {
        return [];
      }

      final files = invoicesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.pdf'))
          .toList();

      // Sort by modified date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      return files;
    } catch (e) {
      throw InvoicePdfException('Failed to get saved invoices: $e');
    }
  }

  /// Delete saved invoice PDF
  static Future<void> deleteSavedInvoice(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw InvoicePdfException('Failed to delete invoice: $e');
    }
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      throw InvoicePdfException('Failed to get file size: $e');
    }
  }
}

/// Custom exception for PDF operations
class InvoicePdfException implements Exception {
  final String message;
  InvoicePdfException(this.message);

  @override
  String toString() => 'InvoicePdfException: $message';
}
