import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';

class ModernInvoicePdfBuilder {
  /// Build a modern invoice PDF page
  static pw.Page buildModernPage(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Column(
          children: [
            _buildModernHeader(invoice, businessInfo),
            pw.SizedBox(height: 30),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 20),
            _buildClientSection(invoice),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 20),
            _buildTotalsSection(invoice),
            pw.Spacer(),
            _buildModernFooter(invoice),
          ],
        );
      },
    );
  }

  /// Modern header with gradient-like effect
  static pw.Widget _buildModernHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromHex('#3b82f6'),
            width: 3,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Business info (left)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessInfo?['name'] ?? 'Your Company',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1e40af'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                businessInfo?['address'] ?? '',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),

          // Invoice label (right)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#e5e7eb'),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Invoice number, date, and status
  static pw.Widget _buildInvoiceDetails(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Invoice number
        _buildDetailColumn('Invoice Number', invoice.invoiceNumber ?? 'N/A'),

        // Invoice date
        _buildDetailColumn(
          'Invoice Date',
          dateFormat.format(invoice.createdAt),
        ),

        // Due date
        _buildDetailColumn(
          'Due Date',
          invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : 'N/A',
        ),

        // Status badge
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _getStatusColor(invoice.status),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            invoice.status.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  /// Build detail column (label + value)
  static pw.Widget _buildDetailColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Client information section with modern styling
  static pw.Widget _buildClientSection(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Bill To section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.clientName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.clientEmail,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),

          // Amount due (right side)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'AMOUNT DUE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#3b82f6'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Items table with modern styling
  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfColor.fromHex('#e5e7eb')),
        bottom: pw.BorderSide(color: PdfColor.fromHex('#e5e7eb')),
        horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#f3f4f6')),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FlexColumnWidth(1), // Qty
        2: const pw.FlexColumnWidth(1.5), // Unit Price
        3: const pw.FlexColumnWidth(1.5), // Total
      },
      children: [
        // Header row with modern styling
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f9fafb'),
          ),
          children: [
            _buildTableHeaderCell('Description'),
            _buildTableHeaderCell('Qty', alignment: pw.TextAlign.center),
            _buildTableHeaderCell('Unit Price', alignment: pw.TextAlign.right),
            _buildTableHeaderCell('Total', alignment: pw.TextAlign.right),
          ],
        ),

        // Item rows
        ...invoice.items.map((item) {
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.description,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  item.quantity.toString(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  '${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  '${invoice.currency} ${total.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1e40af'),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Table header cell styling
  static pw.Widget _buildTableHeaderCell(
    String text, {
    pw.TextAlign alignment = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        textAlign: alignment,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Modern totals section with visual separation
  static pw.Widget _buildTotalsSection(InvoiceModel invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Subtotal
            _buildTotalRow(
              'Subtotal',
              '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}',
              color: PdfColors.grey700,
            ),

            pw.SizedBox(height: 8),

            // Tax
            _buildTotalRow(
              'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)',
              '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}',
              color: PdfColors.grey700,
            ),

            // Divider
            pw.SizedBox(height: 12),
            pw.Container(
              height: 1,
              color: PdfColor.fromHex('#e5e7eb'),
            ),
            pw.SizedBox(height: 12),

            // Total (highlighted)
            _buildTotalRow(
              'TOTAL',
              '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
              color: PdfColor.fromHex('#3b82f6'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build total row
  static pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
            color: color ?? PdfColors.black,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Modern footer
  static pw.Widget _buildModernFooter(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          height: 1,
          color: PdfColor.fromHex('#e5e7eb'),
          margin: const pw.EdgeInsets.symmetric(vertical: 16),
        ),
        if (invoice.notes != null && invoice.notes!.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NOTES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.notes!,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  height: 1.5,
                ),
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3b82f6'),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Generated by AuraSphere Pro • www.aurasphere.app',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ),
      ],
    );
  }

  /// Get status color based on invoice status
  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return PdfColor.fromHex('#6b7280');
      case 'sent':
        return PdfColor.fromHex('#f59e0b');
      case 'paid':
        return PdfColor.fromHex('#10b981');
      case 'overdue':
        return PdfColor.fromHex('#ef4444');
      case 'cancelled':
        return PdfColor.fromHex('#8b5cf6');
      default:
        return PdfColor.fromHex('#6b7280');
    }
  }
}
