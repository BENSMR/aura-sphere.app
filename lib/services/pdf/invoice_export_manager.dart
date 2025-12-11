import 'package:printing/printing.dart';
import 'invoice_pdf_generator.dart';

class InvoiceExportManager {
  static Future<void> previewInvoice({
    required context,
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
    final pdf = await InvoicePdfService.generateInvoicePdf(
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

    await Printing.layoutPdf(
      onLayout: (_) => pdf,
    );
  }
}
