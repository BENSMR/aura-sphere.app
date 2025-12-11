import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';

class InvoicePdfTemplateFactory {
  /// Main factory method - returns PDF page based on template type
  static pw.Page buildPage(
    String templateType,
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return _buildModernTemplate(invoice, businessInfo, customization);

      case 'classic':
        return _buildClassicTemplate(invoice, businessInfo, customization);

      case 'dark':
        return _buildDarkTemplate(invoice, businessInfo, customization);

      case 'gradient':
        return _buildGradientTemplate(invoice, businessInfo, customization);

      case 'minimal':
        return _buildMinimalTemplate(invoice, businessInfo, customization);

      case 'business':
        return _buildBusinessTemplate(invoice, businessInfo, customization);

      default:
        return _buildModernTemplate(invoice, businessInfo, customization);
    }
  }

  /// Modern template - contemporary design
  static pw.Page _buildModernTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) {
    final primaryColor = customization?['primaryColor'] ?? '#3b82f6';
    final accentColor = customization?['accentColor'] ?? '#60a5fa';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Column(
          children: [
            _buildModernHeader(invoice, businessInfo, primaryColor),
            pw.SizedBox(height: 30),
            _buildInvoiceDetailsRow(invoice),
            pw.SizedBox(height: 20),
            _buildClientBox(invoice, primaryColor),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, primaryColor),
            pw.SizedBox(height: 20),
            _buildTotalsSection(invoice, primaryColor),
            pw.Spacer(),
            _buildFooter(invoice, primaryColor),
          ],
        );
      },
    );
  }

  /// Classic template - traditional professional design
  static pw.Page _buildClassicTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.times(),
        bold: pw.Font.timesBold(),
      ),
      build: (context) {
        return pw.Column(
          children: [
            _buildClassicHeader(invoice, businessInfo),
            pw.SizedBox(height: 40),
            _buildClassicInvoiceInfo(invoice),
            pw.SizedBox(height: 30),
            _buildClassicClientSection(invoice),
            pw.SizedBox(height: 25),
            _buildClassicItemsTable(invoice),
            pw.SizedBox(height: 25),
            _buildClassicTotals(invoice),
            pw.Spacer(),
            _buildClassicFooter(invoice),
          ],
        );
      },
    );
  }

  /// Dark template - luxury dark theme
  static pw.Page _buildDarkTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) {
    const accentColor = '#fbbf24'; // Gold accent

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Container(
          color: PdfColor.fromHex('#0f0f0f'),
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            children: [
              _buildDarkHeader(invoice, businessInfo),
              pw.SizedBox(height: 30),
              _buildDarkInvoiceInfo(invoice),
              pw.SizedBox(height: 25),
              _buildDarkClientSection(invoice),
              pw.SizedBox(height: 25),
              _buildDarkItemsTable(invoice, accentColor),
              pw.SizedBox(height: 25),
              _buildDarkTotals(invoice, accentColor),
              pw.Spacer(),
              _buildDarkFooter(invoice, accentColor),
            ],
          ),
        );
      },
    );
  }

  /// Gradient template - vibrant with gradient effects
  static pw.Page _buildGradientTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) {
    const gradientStart = '#8b5cf6'; // Purple
    const gradientEnd = '#ec4899'; // Pink

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Column(
          children: [
            _buildGradientHeader(invoice, businessInfo, gradientStart, gradientEnd),
            pw.SizedBox(height: 35),
            _buildGradientInvoiceInfo(invoice, gradientStart),
            pw.SizedBox(height: 25),
            _buildGradientClientSection(invoice, gradientStart),
            pw.SizedBox(height: 25),
            _buildGradientItemsTable(invoice, gradientStart),
            pw.SizedBox(height: 25),
            _buildGradientTotals(invoice, gradientStart, gradientEnd),
            pw.Spacer(),
            _buildGradientFooter(invoice, gradientStart),
          ],
        );
      },
    );
  }

  /// Minimal template - stripped down, content-focused
  static pw.Page _buildMinimalTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
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
            _buildMinimalHeader(invoice, businessInfo),
            pw.SizedBox(height: 25),
            _buildMinimalContent(invoice),
            pw.Spacer(),
            _buildMinimalFooter(invoice),
          ],
        );
      },
    );
  }

  /// Business template - corporate professional
  static pw.Page _buildBusinessTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) {
    const corporateBlue = '#0f172a';
    const accentBlue = '#0ea5e9';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
      build: (context) {
        return pw.Column(
          children: [
            _buildBusinessHeader(invoice, businessInfo, corporateBlue),
            pw.SizedBox(height: 30),
            _buildBusinessContent(invoice, accentBlue),
            pw.Spacer(),
            _buildBusinessFooter(invoice, corporateBlue),
          ],
        );
      },
    );
  }

  // ============================================================================
  // MODERN TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildModernHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    String primaryColor,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex(primaryColor), width: 3),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessInfo?['name'] ?? 'Company Name',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex(primaryColor),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                businessInfo?['address'] ?? '',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetailsRow(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailColumn('Invoice #', invoice.invoiceNumber ?? 'N/A'),
        _buildDetailColumn('Date', dateFormat.format(invoice.createdAt)),
        _buildDetailColumn(
          'Due',
          invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : 'N/A',
        ),
        _buildStatusBadge(invoice.status),
      ],
    );
  }

  static pw.Widget _buildDetailColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusBadge(String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildClientBox(InvoiceModel invoice, String primaryColor) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
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
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.clientEmail,
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          ),
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
                  color: PdfColor.fromHex(primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice, String primaryColor) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfColor.fromHex('#e5e7eb')),
        bottom: pw.BorderSide(color: PdfColor.fromHex('#e5e7eb')),
        horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#f3f4f6')),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f9fafb')),
          children: [
            _buildTableHeader('Description'),
            _buildTableHeader('Qty', alignment: pw.TextAlign.center),
            _buildTableHeader('Unit Price', alignment: pw.TextAlign.right),
            _buildTableHeader('Total', alignment: pw.TextAlign.right),
          ],
        ),
        ...invoice.items.map((item) {
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              _buildTableCell(item.description),
              _buildTableCell(item.quantity.toString(), alignment: pw.TextAlign.center),
              _buildTableCell('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                  alignment: pw.TextAlign.right),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  '${invoice.currency} ${total.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex(primaryColor),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign alignment = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        textAlign: alignment,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.TextAlign alignment = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        textAlign: alignment,
        style: pw.TextStyle(fontSize: 11),
      ),
    );
  }

  static pw.Widget _buildTotalsSection(InvoiceModel invoice, String primaryColor) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal', '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
            pw.SizedBox(height: 8),
            _buildTotalRow('Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)',
                '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}'),
            pw.SizedBox(height: 12),
            pw.Container(height: 1, color: PdfColor.fromHex('#e5e7eb')),
            pw.SizedBox(height: 12),
            _buildTotalRow(
              'TOTAL',
              '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isBold = false,
    double fontSize = 12,
    String? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
            color: color != null ? PdfColor.fromHex(color) : PdfColors.black,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color != null ? PdfColor.fromHex(color) : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(InvoiceModel invoice, String primaryColor) {
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
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.notes!,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, height: 1.5),
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
              color: PdfColor.fromHex(primaryColor),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Generated by AuraSphere Pro',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CLASSIC TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildClassicHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          businessInfo?['name']?.toString().toUpperCase() ?? 'COMPANY NAME',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          businessInfo?['address'] ?? '',
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildClassicInvoiceInfo(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE #: ${invoice.invoiceNumber ?? "N/A"}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Date: ${dateFormat.format(invoice.createdAt)}', style: pw.TextStyle(fontSize: 11)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Status: ${invoice.status.toUpperCase()}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Due: ${invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : "N/A"}',
                style: pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClassicClientSection(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildClassicItemsTable(InvoiceModel invoice) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('QTY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('UNIT PRICE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        ...invoice.items.map((item) {
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              pw.Text(item.description, style: pw.TextStyle(fontSize: 10)),
              pw.Text(item.quantity.toString(), style: pw.TextStyle(fontSize: 10)),
              pw.Text('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.Text('${invoice.currency} ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildClassicTotals(InvoiceModel invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
                pw.Text('${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tax:', style: pw.TextStyle(fontSize: 10)),
                pw.Text('${invoice.currency} ${invoice.tax.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildClassicFooter(InvoiceModel invoice) {
    return pw.Center(
      child: pw.Text(
        'Thank you for your business',
        style: pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // ============================================================================
  // DARK TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildDarkHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          businessInfo?['name'] ?? 'Company',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          businessInfo?['address'] ?? '',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey300),
        ),
      ],
    );
  }

  static pw.Widget _buildDarkInvoiceInfo(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildDarkDetailColumn('Invoice #', invoice.invoiceNumber ?? 'N/A'),
        _buildDarkDetailColumn('Date', dateFormat.format(invoice.createdAt)),
        _buildDarkDetailColumn(
          'Due',
          invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : 'N/A',
        ),
      ],
    );
  }

  static pw.Widget _buildDarkDetailColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ],
    );
  }

  static pw.Widget _buildDarkClientSection(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#333333')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              pw.SizedBox(height: 8),
              pw.Text(invoice.clientName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('AMOUNT DUE', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              pw.SizedBox(height: 8),
              pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#fbbf24'))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDarkItemsTable(InvoiceModel invoice, String accentColor) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfColor.fromHex('#333333')),
        bottom: pw.BorderSide(color: PdfColor.fromHex('#333333')),
        horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#1a1a1a')),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1a1a1a')),
          children: [
            _buildDarkTableHeader('Description'),
            _buildDarkTableHeader('Qty'),
            _buildDarkTableHeader('Unit Price'),
            _buildDarkTableHeader('Total'),
          ],
        ),
        ...invoice.items.map((item) {
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              _buildDarkTableCell(item.description),
              _buildDarkTableCell(item.quantity.toString()),
              _buildDarkTableCell('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  '${invoice.currency} ${total.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(accentColor)),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildDarkTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400),
      ),
    );
  }

  static pw.Widget _buildDarkTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey200),
      ),
    );
  }

  static pw.Widget _buildDarkTotals(InvoiceModel invoice, String accentColor) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildDarkTotalRow('Subtotal', '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
            pw.SizedBox(height: 8),
            _buildDarkTotalRow('Tax', '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}'),
            pw.SizedBox(height: 12),
            pw.Container(height: 1, color: PdfColor.fromHex('#333333')),
            pw.SizedBox(height: 12),
            _buildDarkTotalRow(
              'TOTAL',
              '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDarkTotalRow(
    String label,
    String amount, {
    bool isBold = false,
    double fontSize = 12,
    String? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : null,
            color: color != null ? PdfColor.fromHex(color) : PdfColors.grey300,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: color != null ? PdfColor.fromHex(color) : PdfColors.white,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDarkFooter(InvoiceModel invoice, String accentColor) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Container(height: 1, color: PdfColor.fromHex('#333333'), margin: const pw.EdgeInsets.symmetric(vertical: 12)),
          pw.Text(
            'Thank you for your business',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(accentColor)),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'AuraSphere Pro',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // GRADIENT TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildGradientHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    String gradientStart,
    String gradientEnd,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex(gradientStart), width: 4),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessInfo?['name'] ?? 'Company',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex(gradientStart),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                businessInfo?['address'] ?? '',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(gradientEnd),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGradientInvoiceInfo(InvoiceModel invoice, String primaryColor) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailColumn('Invoice #', invoice.invoiceNumber ?? 'N/A'),
        _buildDetailColumn('Date', dateFormat.format(invoice.createdAt)),
        _buildDetailColumn(
          'Due',
          invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : 'N/A',
        ),
        _buildStatusBadge(invoice.status),
      ],
    );
  }

  static pw.Widget _buildGradientClientSection(InvoiceModel invoice, String primaryColor) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex(primaryColor)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(primaryColor))),
              pw.SizedBox(height: 8),
              pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('AMOUNT DUE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(primaryColor))),
              pw.SizedBox(height: 8),
              pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(primaryColor))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGradientItemsTable(InvoiceModel invoice, String primaryColor) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfColor.fromHex(primaryColor)),
        bottom: pw.BorderSide(color: PdfColor.fromHex(primaryColor)),
        horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#e5e7eb')),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#f9fafb')),
          children: [
            _buildTableHeader('Description'),
            _buildTableHeader('Qty', alignment: pw.TextAlign.center),
            _buildTableHeader('Unit Price', alignment: pw.TextAlign.right),
            _buildTableHeader('Total', alignment: pw.TextAlign.right),
          ],
        ),
        ...invoice.items.map((item) {
          final total = item.quantity * item.unitPrice;
          return pw.TableRow(
            children: [
              _buildTableCell(item.description),
              _buildTableCell(item.quantity.toString(), alignment: pw.TextAlign.center),
              _buildTableCell('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}', alignment: pw.TextAlign.right),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  '${invoice.currency} ${total.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(primaryColor)),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildGradientTotals(InvoiceModel invoice, String gradientStart, String gradientEnd) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal', '${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}'),
            pw.SizedBox(height: 8),
            _buildTotalRow('Tax', '${invoice.currency} ${invoice.tax.toStringAsFixed(2)}'),
            pw.SizedBox(height: 12),
            pw.Container(height: 1, color: PdfColor.fromHex(gradientStart)),
            pw.SizedBox(height: 12),
            _buildTotalRow(
              'TOTAL',
              '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
              color: gradientStart,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildGradientFooter(InvoiceModel invoice, String primaryColor) {
    return pw.Center(
      child: pw.Text(
        'Thank you for your business • AuraSphere Pro',
        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex(primaryColor)),
      ),
    );
  }

  // ============================================================================
  // MINIMAL TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildMinimalHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
  ) {
    return pw.Text(
      businessInfo?['name']?.toString().toUpperCase() ?? 'INVOICE',
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _buildMinimalContent(InvoiceModel invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Invoice: ${invoice.invoiceNumber ?? "N/A"}', style: pw.TextStyle(fontSize: 11)),
            pw.Text('Date: ${dateFormat.format(invoice.createdAt)}', style: pw.TextStyle(fontSize: 11)),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 11)),
        pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 15),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Text('Description', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Unit Price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            ...invoice.items.map((item) {
              final total = item.quantity * item.unitPrice;
              return pw.TableRow(
                children: [
                  pw.Text(item.description, style: pw.TextStyle(fontSize: 10)),
                  pw.Text(item.quantity.toString(), style: pw.TextStyle(fontSize: 10)),
                  pw.Text('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('${invoice.currency} ${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 150,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('${invoice.currency} ${invoice.tax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMinimalFooter(InvoiceModel invoice) {
    return pw.Center(
      child: pw.Text('Generated by AuraSphere Pro', style: pw.TextStyle(fontSize: 8)),
    );
  }

  // ============================================================================
  // BUSINESS TEMPLATE HELPERS
  // ============================================================================

  static pw.Widget _buildBusinessHeader(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    String corporateBlue,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(corporateBlue),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            businessInfo?['name'] ?? 'Company',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            businessInfo?['address'] ?? '',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey200),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBusinessContent(InvoiceModel invoice, String accentBlue) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INVOICE NUMBER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.Text(invoice.invoiceNumber ?? 'N/A', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Invoice Date', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.Text(dateFormat.format(invoice.createdAt), style: pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 25),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('AMOUNT DUE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(accentBlue))),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Text('Description', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Unit Price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            ...invoice.items.map((item) {
              final total = item.quantity * item.unitPrice;
              return pw.TableRow(
                children: [
                  pw.Text(item.description, style: pw.TextStyle(fontSize: 10)),
                  pw.Text(item.quantity.toString(), style: pw.TextStyle(fontSize: 10)),
                  pw.Text('${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('${invoice.currency} ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('${invoice.currency} ${invoice.tax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex(accentBlue))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBusinessFooter(InvoiceModel invoice, String corporateBlue) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex(corporateBlue), width: 2),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          'Thank you for your business • www.aurasphere.app',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

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
