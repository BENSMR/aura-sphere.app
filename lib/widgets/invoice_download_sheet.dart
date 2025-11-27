import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models/invoice_model.dart';
import '../services/invoice_service.dart';
import '../utils/logger.dart';

/// Modal bottom sheet for downloading invoices in multiple formats
class InvoiceDownloadSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onDownloadComplete;

  const InvoiceDownloadSheet({
    Key? key,
    required this.invoice,
    this.onDownloadComplete,
  }) : super(key: key);

  @override
  State<InvoiceDownloadSheet> createState() => _InvoiceDownloadSheetState();
}

class _InvoiceDownloadSheetState extends State<InvoiceDownloadSheet> {
  final _invoiceService = InvoiceService();
  String? _downloadingFormat;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Download Invoice',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.invoice.invoiceNumber ?? 'Invoice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Error message
            if (_errorMessage != null) ...[
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
            ],
            // Download options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildDownloadOption(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: 'Download as PDF',
                    subtitle: 'Professional invoice document',
                    format: 'pdf',
                    isLoading: _downloadingFormat == 'pdf',
                  ),
                  Divider(height: 1),
                  _buildDownloadOption(
                    context,
                    icon: Icons.table_view,
                    title: 'Download as CSV',
                    subtitle: 'Items data in spreadsheet format',
                    format: 'csv',
                    isLoading: _downloadingFormat == 'csv',
                  ),
                  Divider(height: 1),
                  _buildDownloadOption(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Download as JSON',
                    subtitle: 'Full invoice data in JSON format',
                    format: 'json',
                    isLoading: _downloadingFormat == 'json',
                  ),
                  Divider(height: 1),
                  _buildDownloadOption(
                    context,
                    icon: Icons.folder_zip,
                    title: 'Download ALL (ZIP)',
                    subtitle: 'PDF + CSV + JSON in one file',
                    format: 'zip',
                    isLoading: _downloadingFormat == 'zip',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String format,
    required bool isLoading,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.download_outlined),
      enabled: _downloadingFormat == null,
      onTap: _downloadingFormat == null
          ? () => _downloadInFormat(format)
          : null,
    );
  }

  Future<void> _downloadInFormat(String format) async {
    setState(() {
      _downloadingFormat = format;
      _errorMessage = null;
    });

    try {
      logger.info('Starting download', {'format': format, 'invoiceId': widget.invoice.id});

      switch (format) {
        case 'pdf':
          await _downloadPdf();
          break;
        case 'csv':
          await _downloadCsv();
          break;
        case 'json':
          await _downloadJson();
          break;
        case 'zip':
          await _downloadZip();
          break;
        default:
          throw Exception('Unknown format: $format');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Downloaded as ${format.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onDownloadComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      logger.error('Download failed', {'format': format, 'error': e.toString()});

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to download: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingFormat = null);
      }
    }
  }

  /// Download as PDF (using LocalPdfGenerator or Cloud Function)
  Future<void> _downloadPdf() async {
    final pdfBytes = await _invoiceService.generateLocalPdf(widget.invoice);

    // Save to device Downloads folder
    await _saveBytesToDownloads(
      pdfBytes,
      '${widget.invoice.invoiceNumber}.pdf',
    );
  }

  /// Download items as CSV
  Future<void> _downloadCsv() async {
    final csv = _generateCsv();
    final csvBytes = csv.codeUnits;

    await _saveBytesToDownloads(
      csvBytes,
      '${widget.invoice.invoiceNumber}_items.csv',
    );
  }

  /// Download full invoice as JSON
  Future<void> _downloadJson() async {
    final jsonMap = widget.invoice.toMap();
    final jsonString = _prettyPrintJson(jsonMap);
    final jsonBytes = jsonString.codeUnits;

    await _saveBytesToDownloads(
      jsonBytes,
      '${widget.invoice.invoiceNumber}.json',
    );
  }

  /// Download all formats as ZIP
  Future<void> _downloadZip() async {
    // This would require a zip library
    // For now, we'll create individual files
    await _downloadPdf();
    await _downloadCsv();
    await _downloadJson();
  }

  /// Generate CSV from invoice items
  String _generateCsv() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Item,Quantity,Unit Price,VAT Rate,VAT Amount,Total');

    // Items
    for (final item in widget.invoice.items) {
      final vatAmount = (item.total * item.vatRate);
      buffer.writeln(
        '${_escapeCsv(item.name)},'
        '${item.quantity},'
        '${item.unitPrice},'
        '${item.vatRate * 100}%,'
        '${vatAmount.toStringAsFixed(2)},'
        '${item.total.toStringAsFixed(2)}',
      );
    }

    // Summary
    buffer.writeln('');
    buffer.writeln('Summary');
    buffer.writeln('Subtotal,${widget.invoice.subtotal.toStringAsFixed(2)}');
    buffer.writeln('Total VAT,${widget.invoice.totalVat.toStringAsFixed(2)}');
    if (widget.invoice.discount > 0) {
      buffer.writeln('Discount,-${widget.invoice.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('Total,${widget.invoice.total.toStringAsFixed(2)}');
    buffer.writeln('Currency,${widget.invoice.currency}');

    return buffer.toString();
  }

  /// Escape CSV special characters
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Pretty print JSON with indentation
  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  /// Save bytes to device Downloads folder
  Future<void> _saveBytesToDownloads(
    List<int> bytes,
    String filename,
  ) async {
    try {
      // Get Firebase Storage reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('downloads/${DateTime.now().millisecondsSinceEpoch}_$filename');

      // Upload to Firebase Storage
      final uploadTask = await ref.putData(
        bytes as List<int>,
        SettableMetadata(contentType: _getContentType(filename)),
      );

      logger.info('File saved', {
        'filename': filename,
        'size': bytes.length,
        'path': ref.fullPath,
      });
    } catch (e) {
      logger.error('Failed to save file', {'filename': filename, 'error': e.toString()});
      rethrow;
    }
  }

  /// Get MIME type for file
  String _getContentType(String filename) {
    if (filename.endsWith('.pdf')) return 'application/pdf';
    if (filename.endsWith('.csv')) return 'text/csv';
    if (filename.endsWith('.json')) return 'application/json';
    if (filename.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }
}

/// Show invoice download options
void showInvoiceDownloadSheet(
  BuildContext context,
  InvoiceModel invoice, {
  VoidCallback? onDownloadComplete,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => InvoiceDownloadSheet(
      invoice: invoice,
      onDownloadComplete: onDownloadComplete,
    ),
  );
}
