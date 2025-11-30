import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../data/models/invoice_model.dart';
import '../data/models/expense_model.dart';

/// Generate PDF documents locally without server processing
class LocalPdfGenerator {
  /// Generate invoice PDF with items, totals, and linked expenses summary
  static Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.invoiceNumber ?? 'INV-000',
                    style: pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xFF666666)),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Status: ${_getStatusLabel(invoice.status)}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.currency,
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Client & Invoice Details
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "BILL TO:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 12)),
                  pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
                  if (invoice.projectId != null)
                    pw.Text(
                      "Project: ${invoice.projectId}",
                      style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF666666)),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Invoice Date:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _formatDate(invoice.createdAt.toDate()),
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "Due Date:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _formatDate(invoice.dueDate),
                    style: pw.TextStyle(fontSize: 11),
                  ),
                  if (invoice.paidDate != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "Paid Date:",
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatDate(invoice.paidDate!),
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Description
              1: const pw.FlexColumnWidth(1.2), // Quantity
              2: const pw.FlexColumnWidth(1.5), // Unit Price
              3: const pw.FlexColumnWidth(1), // VAT Rate
              4: const pw.FlexColumnWidth(1.5), // Total
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                children: [
                  _buildTableCell("Description", isHeader: true),
                  _buildTableCell("Qty", isHeader: true, alignment: pw.Alignment.center),
                  _buildTableCell("Unit Price", isHeader: true, alignment: pw.Alignment.centerRight),
                  _buildTableCell("VAT %", isHeader: true, alignment: pw.Alignment.center),
                  _buildTableCell("Total", isHeader: true, alignment: pw.Alignment.centerRight),
                ],
              ),
              // Data Rows
              ...invoice.items.map((item) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(item.name),
                    _buildTableCell(
                      item.quantity.toStringAsFixed(2),
                      alignment: pw.Alignment.center,
                    ),
                    _buildTableCell(
                      "${item.unitPrice.toStringAsFixed(2)} ${invoice.currency}",
                      alignment: pw.Alignment.centerRight,
                    ),
                    _buildTableCell(
                      "${(item.vatRate * 100).toStringAsFixed(0)}%",
                      alignment: pw.Alignment.center,
                    ),
                    _buildTableCell(
                      "${item.total.toStringAsFixed(2)} ${invoice.currency}",
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 20),

          // Totals Section
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 11)),
                      pw.Text(
                        "${invoice.subtotal.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total VAT:", style: pw.TextStyle(fontSize: 11)),
                      pw.Text(
                        "${invoice.totalVat.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  if (invoice.discount > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Discount:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text(
                          "-${invoice.discount.toStringAsFixed(2)} ${invoice.currency}",
                          style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFFD32F2F)),
                        ),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "TOTAL:",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "${invoice.total.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Notes Section (if present)
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Divider(height: 1),
            pw.SizedBox(height: 12),
            pw.Text(
              "Notes:",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              invoice.notes!,
              style: pw.TextStyle(fontSize: 9),
            ),
          ],

          // Linked Expenses Summary (if present)
          if (invoice.hasLinkedExpenses) ...[
            pw.SizedBox(height: 24),
            pw.Divider(height: 1),
            pw.SizedBox(height: 12),
            pw.Text(
              "Linked Expenses (${invoice.linkedExpenseCount}):",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "This invoice is linked to ${invoice.linkedExpenseCount} expense(s).",
              style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF666666)),
            ),
          ],

          // Footer
          pw.SizedBox(height: 24),
          pw.Divider(height: 1),
          pw.SizedBox(height: 8),
          pw.Text(
            "Generated on ${_formatDateTime(DateTime.now())}",
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF999999)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate invoice PDF with linked expenses details
  static Future<Uint8List> generateInvoicePdfWithExpenses(
    InvoiceModel invoice,
    List<ExpenseModel> linkedExpenses,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.invoiceNumber ?? 'INV-000',
                    style: pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xFF666666)),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Status: ${_getStatusLabel(invoice.status)}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Client & Invoice Details
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "BILL TO:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 12)),
                  pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Invoice Date: ${_formatDate(invoice.createdAt.toDate())}",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "Due Date: ${_formatDate(invoice.dueDate)}",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Invoice Items Table
          pw.Text(
            "Invoice Items:",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
                children: [
                  _buildTableCell("Description", isHeader: true),
                  _buildTableCell("Qty", isHeader: true, alignment: pw.Alignment.center),
                  _buildTableCell("Unit Price", isHeader: true, alignment: pw.Alignment.centerRight),
                  _buildTableCell("Total", isHeader: true, alignment: pw.Alignment.centerRight),
                ],
              ),
              ...invoice.items.map((item) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(item.name),
                    _buildTableCell(item.quantity.toStringAsFixed(2), alignment: pw.Alignment.center),
                    _buildTableCell(
                      "${item.unitPrice.toStringAsFixed(2)} ${invoice.currency}",
                      alignment: pw.Alignment.centerRight,
                    ),
                    _buildTableCell(
                      "${item.total.toStringAsFixed(2)} ${invoice.currency}",
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 20),

          // Linked Expenses Section (if any)
          if (linkedExpenses.isNotEmpty) ...[
            pw.Text(
              "Linked Expenses (${linkedExpenses.length}):",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
                  children: [
                    _buildTableCell("Merchant", isHeader: true),
                    _buildTableCell("Category", isHeader: true, alignment: pw.Alignment.center),
                    _buildTableCell("Amount", isHeader: true, alignment: pw.Alignment.centerRight),
                    _buildTableCell("Status", isHeader: true, alignment: pw.Alignment.center),
                  ],
                ),
                ...linkedExpenses.map((expense) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(expense.merchant),
                      _buildTableCell(expense.category, alignment: pw.Alignment.center),
                      _buildTableCell(
                        "${expense.amount.toStringAsFixed(2)} ${expense.currency}",
                        alignment: pw.Alignment.centerRight,
                      ),
                      _buildTableCell(
                        _getExpenseStatusLabel(expense.status),
                        alignment: pw.Alignment.center,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Text(
              "Total from linked expenses: ${linkedExpenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)} ${invoice.currency}",
              style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF666666)),
            ),

            pw.SizedBox(height: 20),
          ],

          // Totals Section
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 11)),
                      pw.Text(
                        "${invoice.subtotal.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total VAT:", style: pw.TextStyle(fontSize: 11)),
                      pw.Text(
                        "${invoice.totalVat.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  if (invoice.discount > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Discount:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text(
                          "-${invoice.discount.toStringAsFixed(2)} ${invoice.currency}",
                          style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFFD32F2F)),
                        ),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "TOTAL:",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "${invoice.total.toStringAsFixed(2)} ${invoice.currency}",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Divider(height: 1),
            pw.SizedBox(height: 12),
            pw.Text(
              "Notes:",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              invoice.notes!,
              style: pw.TextStyle(fontSize: 9),
            ),
          ],

          // Footer
          pw.SizedBox(height: 24),
          pw.Divider(height: 1),
          pw.SizedBox(height: 8),
          pw.Text(
            "Generated on ${_formatDateTime(DateTime.now())}",
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF999999)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Helper: Build a table cell with consistent styling
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Helper: Format date to readable string
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Helper: Format datetime with time
  static String _formatDateTime(DateTime dateTime) {
    return "${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Helper: Get invoice status label
  static String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'paid':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Helper: Get expense status label
  static String _getExpenseStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending_approval':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'reimbursed':
        return 'Reimbursed';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}
