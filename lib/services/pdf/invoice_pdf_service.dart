import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/invoice_model.dart';

class InvoicePdfService {
  /// Generate a professional invoice PDF
  static Future<pw.Document> generate(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => _buildHeader(invoice),
        build: (context) => [
          _buildClientSection(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotalsSection(invoice),
          pw.SizedBox(height: 30),
          _buildFooter(invoice),
        ],
      ),
    );

    return pdf;
  }

  /// Instance method for generating PDF with expenses
  Future<List<int>> generateLocalPdfWithExpenses(
    InvoiceModel invoice,
    List<dynamic> expenses,
  ) async {
    // Placeholder implementation
    return [];
  }

  /// Instance method for generating local PDF
  Future<List<int>> generateLocalPdf(InvoiceModel invoice) async {
    // Placeholder implementation
    return [];
  }

  /// Header with logo/branding and invoice number
  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 30),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AURASPHERE PRO',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1e40af'), // Blue
                ),
              ),
              pw.Text(
                'Professional Invoice Management',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Invoice',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                invoice.invoiceNumber ?? 'N/A',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1e40af'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Client information section
  static pw.Widget _buildClientSection(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final createdDate = dateFormat.format(invoice.createdAt);
    final dueDate = invoice.dueDate != null
        ? dateFormat.format(invoice.dueDate!)
        : 'Not specified';
    final paidDate = invoice.paidDate != null
        ? dateFormat.format(invoice.paidDate!)
        : '—';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    invoice.clientName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    invoice.clientEmail,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (invoice.clientId != null)
                    pw.Text(
                      'Client ID: ${invoice.clientId}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildDateRow('Invoice Date:', createdDate),
                  pw.SizedBox(height: 8),
                  _buildDateRow('Due Date:', dueDate),
                  pw.SizedBox(height: 8),
                  _buildDateRow('Paid Date:', paidDate),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _getStatusColor(invoice.status),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      invoice.status.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Date row helper
  static pw.Widget _buildDateRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Items table
  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FlexColumnWidth(1), // Qty
        2: const pw.FlexColumnWidth(1.5), // Unit Price
        3: const pw.FlexColumnWidth(1.5), // Total
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f3f4f6'),
          ),
          children: [
            _buildTableHeader('Description'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Unit Price'),
            _buildTableHeader('Total'),
          ],
        ),
        // Item rows
        ...invoice.items.asMap().entries.map((entry) {
          final item = entry.value;
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.description,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.quantity.toString(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${invoice.currency} ${total.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Table header cell
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  /// Totals section (right-aligned)
  static pw.Widget _buildTotalsSection(InvoiceModel invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(right: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow(
            'Subtotal:',
            '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 8),
          _buildTotalRow(
            'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):',
            '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}',
          ),
          pw.Divider(
            color: PdfColors.grey300,
          ),
          _buildTotalRow(
            'TOTAL:',
            '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  /// Total row helper
  static pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isBold ? PdfColor.fromHex('#1e40af') : PdfColors.grey800,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            amount,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: isBold ? PdfColor.fromHex('#1e40af') : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Footer with notes
  static pw.Widget _buildFooter(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Thank you for your business! Please remit payment by the due date.',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Generated by AuraSphere Pro',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on invoice status
  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return PdfColor.fromHex('#6b7280'); // Gray
      case 'sent':
        return PdfColor.fromHex('#f59e0b'); // Amber
      case 'paid':
        return PdfColor.fromHex('#10b981'); // Green
      case 'overdue':
        return PdfColor.fromHex('#ef4444'); // Red
      case 'cancelled':
        return PdfColor.fromHex('#8b5cf6'); // Purple
      default:
        return PdfColor.fromHex('#6b7280');
    }
  }
}
