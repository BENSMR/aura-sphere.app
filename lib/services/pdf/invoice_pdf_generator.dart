import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf({
    required String invoiceNumber,
    required String clientName,
    required String clientEmail,
    required double amount,
    required String currency,
    required DateTime date,
    String? notes,
    required List<Map<String, dynamic>> items, // name, qty, price
    required Map<String, dynamic> business, // name, logo, address
  }) async {
    final pdf = pw.Document();

    final formatter = NumberFormat.currency(symbol: currency + " ");

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr,
        ),
        build: (context) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Business branding
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    business['name'],
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  if (business['address'] != null)
                    pw.Text(business['address']),
                ],
              ),

              // Invoice info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text("Invoice #: $invoiceNumber"),
                  pw.Text("Date: ${DateFormat('yyyy-MM-dd').format(date)}"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 32),

          // Client info
          pw.Text("Billed To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(clientName),
          pw.Text(clientEmail),
          pw.SizedBox(height: 24),

          // ITEMS TABLE
          pw.Table.fromTextArray(
            headers: ["Item", "Qty", "Price", "Total"],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: items.map((item) {
              return [
                item['name'],
                item['qty'].toString(),
                formatter.format(item['price']),
                formatter.format(item['qty'] * item['price']),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 16),

          // TOTAL AMOUNT
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                "Total: ${formatter.format(amount)}",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // NOTES
          if (notes != null && notes!.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(notes!),
              ],
            )
        ],
      ),
    );

    return pdf.save();
  }
}
