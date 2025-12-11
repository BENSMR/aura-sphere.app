import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/invoice_model.dart';
import '../core/utils/logger.dart';

/// PDF Export Service
/// 
/// Generates professional PDF invoices with:
/// - Company branding (logo, signature, watermark)
/// - Invoice details and line items
/// - Calculated totals with tax
/// - Professional formatting
/// - Custom footer and header
class PdfExportService {
  final FirebaseAuth _auth;

  PdfExportService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Generate PDF from invoice
  /// 
  /// Returns PDF bytes ready for download/upload
  Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, {
    String? brandingPrefix,
    String? watermarkText,
    String? footerText,
    String? logoUrl,
    String? signatureUrl,
    String? stampUrl,
  }) async {
    try {
      final pdf = pw.Document();

      // Create PDF with invoice content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(invoice, logoUrl, watermarkText),
          footer: (context) => _buildFooter(context, footerText),
          build: (context) => [
            _buildInvoiceTitle(invoice, brandingPrefix),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 30),
            _buildLineItems(invoice),
            pw.SizedBox(height: 20),
            _buildTotals(invoice),
            pw.SizedBox(height: 30),
            if (signatureUrl != null || stampUrl != null)
              _buildSignatureSection(signatureUrl, stampUrl),
          ],
        ),
      );

      final bytes = await pdf.save();
      Logger.info('PDF generated: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      Logger.error('Error generating PDF: $e');
      rethrow;
    }
  }

  /// Generate PDF with linked expenses
  /// 
  /// Includes expense breakdown as additional page
  Future<Uint8List> generateInvoicePdfWithExpenses(
    InvoiceModel invoice,
    List<Map<String, dynamic>> expenses, {
    String? brandingPrefix,
    String? watermarkText,
    String? footerText,
    String? logoUrl,
    String? signatureUrl,
    String? stampUrl,
  }) async {
    try {
      final pdf = pw.Document();

      // Main invoice page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(invoice, logoUrl, watermarkText),
          footer: (context) => _buildFooter(context, footerText),
          build: (context) => [
            _buildInvoiceTitle(invoice, brandingPrefix),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 30),
            _buildLineItems(invoice),
            pw.SizedBox(height: 20),
            _buildTotals(invoice),
          ],
        ),
      );

      // Expenses page
      if (expenses.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            header: (context) =>
                _buildExpensesHeader(invoice, watermarkText),
            footer: (context) => _buildFooter(context, footerText),
            build: (context) => [
              _buildExpensesTable(expenses),
            ],
          ),
        );
      }

      final bytes = await pdf.save();
      Logger.info('PDF with expenses generated: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      Logger.error('Error generating PDF with expenses: $e');
      rethrow;
    }
  }

  /// Generate simple text/plain PDF
  /// 
  /// Lightweight alternative for basic invoices
  Future<Uint8List> generateSimpleInvoicePdf(
    InvoiceModel invoice, {
    String? brandingPrefix,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Invoice #: ${brandingPrefix ?? 'INV'}-${invoice.invoiceNumber}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Date: ${_formatDate(invoice.createdAt)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                invoice.clientName,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                invoice.clientEmail,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 30),
              _buildSimpleLineItems(invoice),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Subtotal: ${invoice.currency} ${(invoice.subtotal).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%): ${invoice.currency} ${invoice.tax.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Total: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      Logger.info('Simple PDF generated: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      Logger.error('Error generating simple PDF: $e');
      rethrow;
    }
  }

  // ==================== Builders ====================

  pw.Widget _buildHeader(
    InvoiceModel invoice,
    String? logoUrl,
    String? watermarkText,
  ) {
    return pw.Column(
      children: [
        if (watermarkText != null)
          pw.Opacity(
            opacity: 0.1,
            child: pw.Text(
              watermarkText.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 60,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, String? footerText) {
    return pw.Column(
      children: [
        pw.Divider(),
        if (footerText != null)
          pw.Text(
            footerText,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceTitle(
    InvoiceModel invoice,
    String? prefix,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INVOICE',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Invoice #: ${prefix ?? 'INV'}-${invoice.invoiceNumber}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bill To:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(invoice.clientName),
            pw.Text(invoice.clientEmail),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice Date: ${_formatDate(invoice.createdAt)}',
            ),
            pw.Text(
              'Due Date: ${_formatDate(invoice.dueDate ?? DateTime.now())}',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLineItems(InvoiceModel invoice) {
    final tableRows = <pw.TableRow>[];

    // Header row
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Text('Description',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Qty',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
          pw.Text('Unit Price',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
          pw.Text('Amount',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ],
      ),
    );

    // Item rows
    for (final item in invoice.items) {
      final amount = item.quantity * item.unitPrice;
      tableRows.add(
        pw.TableRow(
          children: [
            pw.Text(item.description),
            pw.Text(item.quantity.toString(),
                textAlign: pw.TextAlign.right),
            pw.Text('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right),
            pw.Text('${invoice.currency} ${amount.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: tableRows,
    );
  }

  pw.Widget _buildSimpleLineItems(InvoiceModel invoice) {
    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        children: [
          pw.Text('Description',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Qty',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
          pw.Text('Unit Price',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
          pw.Text('Amount',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ],
      ),
    );

    for (final item in invoice.items) {
      final amount = item.quantity * item.unitPrice;
      tableRows.add(
        pw.TableRow(
          children: [
            pw.Text(item.description),
            pw.Text(item.quantity.toString(),
                textAlign: pw.TextAlign.right),
            pw.Text('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right),
            pw.Text('${invoice.currency} ${amount.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: tableRows,
    );
  }

  pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Subtotal: ${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
            pw.Text(
              'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%): ${invoice.currency} ${invoice.tax.toStringAsFixed(2)}',
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Total: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignatureSection(String? signatureUrl, String? stampUrl) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (signatureUrl != null)
          pw.Column(
            children: [
              pw.Text('Authorized By:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              // Signature image would be rendered here
              pw.Text('_' * 30),
            ],
          ),
        if (stampUrl != null)
          pw.Column(
            children: [
              pw.Text('Official Stamp:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              // Stamp image would be rendered here
              pw.Text('[STAMP]'),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildExpensesHeader(
    InvoiceModel invoice,
    String? watermarkText,
  ) {
    return pw.Column(
      children: [
        if (watermarkText != null)
          pw.Opacity(
            opacity: 0.1,
            child: pw.Text(
              watermarkText.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 60,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Linked Expenses - Invoice #${invoice.invoiceNumber}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildExpensesTable(List<Map<String, dynamic>> expenses) {
    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        children: [
          pw.Text('Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Description',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Category',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Amount',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right),
        ],
      ),
    );

    for (final expense in expenses) {
      tableRows.add(
        pw.TableRow(
          children: [
            pw.Text(expense['date'] ?? ''),
            pw.Text(expense['description'] ?? ''),
            pw.Text(expense['category'] ?? ''),
            pw.Text(expense['amount']?.toString() ?? '',
                textAlign: pw.TextAlign.right),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: tableRows,
    );
  }

  /// Helper: Format date for PDF
  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}
