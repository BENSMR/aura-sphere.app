import 'package:flutter/material.dart';
import 'package:aura_sphere_pro/models/invoice_model.dart';
import 'package:aura_sphere_pro/services/invoice_service_client.dart';
import 'package:aura_sphere_pro/services/pdf/local_pdf_generator.dart';
import 'package:aura_sphere_pro/utils/logger.dart';

/// Dialog for exporting invoices in multiple formats
///
/// Shows available export formats (PDF, PNG, DOCX, CSV, ZIP) with download buttons.
/// Falls back to local PDF generation if Cloud Function fails.
class InvoiceExportDialog extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onExportComplete;

  const InvoiceExportDialog({
    required this.invoice,
    this.onExportComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<InvoiceExportDialog> createState() => _InvoiceExportDialogState();
}

class _InvoiceExportDialogState extends State<InvoiceExportDialog> {
  late final InvoiceServiceClient _client;
  final Map<String, String> _downloadUrls = {};
  final Map<String, bool> _downloadingStates = {
    'pdf': false,
    'png': false,
    'docx': false,
    'csv': false,
    'zip': false,
  };
  String? _errorMessage;
  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _client = InvoiceServiceClient();
    _initializeExport();
  }

  /// Initialize export by generating all formats
  Future<void> _initializeExport() async {
    setState(() => _isInitialLoading = true);
    try {
      final invoiceData = _buildInvoiceDataForExport();

      logger.i('Initializing export for invoice ${widget.invoice.invoiceNumber}');

      final urls = await _client.exportInvoiceAllFormats(invoiceData);

      setState(() {
        _downloadUrls.addAll(urls);
        _errorMessage = null;
      });

      logger.i('Export successful. Generated ${urls.length} formats');
    } catch (e) {
      logger.e('Export initialization failed: $e');
      setState(() {
        _errorMessage = 'Failed to generate exports. Using local PDF fallback.';
      });
    } finally {
      setState(() => _isInitialLoading = false);
    }
  }

  /// Download a specific format
  Future<void> _downloadFormat(String format) async {
    setState(() => _downloadingStates[format] = true);

    try {
      final url = _downloadUrls[format];

      if (url == null || url.isEmpty) {
        throw Exception('No URL available for $format format');
      }

      logger.i('Opening $format: $url');

      // Open the signed URL in external application
      await _client.openUrl(url);

      logger.i('$format export opened successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$format export opened'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      logger.e('Error opening $format: $e');

      // Fallback for PDF
      if (format == 'pdf') {
        await _fallbackLocalPdf();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open $format: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _downloadingStates[format] = false);
    }
  }

  /// Fallback to local PDF generation
  Future<void> _fallbackLocalPdf() async {
    try {
      logger.i('Falling back to local PDF generation');

      final bytes = await LocalPdfGenerator.generateInvoicePdf(
        widget.invoice,
      );

      // TODO: Save to file or use share/printing plugin
      logger.i('Local PDF generated: ${bytes.length} bytes');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local PDF generated. Save or share using system menu.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      logger.e('Local PDF generation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build invoice data map for Cloud Function
  Map<String, dynamic> _buildInvoiceDataForExport() {
    return {
      'invoiceNumber': widget.invoice.invoiceNumber,
      'invoiceId': widget.invoice.id,
      'createdAt': widget.invoice.createdAt.toIso8601String(),
      'dueDate': widget.invoice.dueDate.toIso8601String(),
      'items': widget.invoice.items
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'description': item.description ?? '',
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'vatRate': item.vatRate,
                'total': item.total,
              })
          .toList(),
      'currency': widget.invoice.currency,
      'subtotal': widget.invoice.subtotal,
      'totalVat': widget.invoice.totalVat,
      'discount': widget.invoice.discount ?? 0,
      'total': widget.invoice.total,
      'businessName': widget.invoice.businessName,
      'businessAddress': widget.invoice.businessAddress ?? '',
      'clientName': widget.invoice.clientName,
      'clientEmail': widget.invoice.clientEmail,
      'clientAddress': widget.invoice.clientAddress ?? '',
      'notes': widget.invoice.notes ?? '',
      'status': widget.invoice.status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export Invoice ${widget.invoice.invoiceNumber}'),
      content: SizedBox(
        width: 400,
        child: _isInitialLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildExportOptions(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Loading state UI
  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Generating export formats...'),
      ],
    );
  }

  /// Error state UI
  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.orange, size: 48),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'An error occurred',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.orange),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _initializeExport,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _fallbackLocalPdf,
          icon: const Icon(Icons.file_download),
          label: const Text('Use Local PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// Export options UI
  Widget _buildExportOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Select format to download:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildFormatButton(
          'PDF',
          Icons.picture_as_pdf,
          Colors.red,
          'pdf',
          '100-300KB • Print-ready',
        ),
        const SizedBox(height: 8),
        _buildFormatButton(
          'PNG',
          Icons.image,
          Colors.blue,
          'png',
          '200-500KB • Screenshot',
        ),
        const SizedBox(height: 8),
        _buildFormatButton(
          'DOCX',
          Icons.description,
          Colors.blueGrey,
          'docx',
          '50-150KB • Editable',
        ),
        const SizedBox(height: 8),
        _buildFormatButton(
          'CSV',
          Icons.table_chart,
          Colors.green,
          'csv',
          '5-50KB • Spreadsheet',
        ),
        const SizedBox(height: 8),
        _buildFormatButton(
          'ZIP',
          Icons.folder_zip,
          Colors.purple,
          'zip',
          '400-900KB • All formats',
        ),
      ],
    );
  }

  /// Build individual format button
  Widget _buildFormatButton(
    String label,
    IconData icon,
    Color color,
    String format,
    String subtitle,
  ) {
    final isDownloading = _downloadingStates[format] ?? false;
    final hasUrl = _downloadUrls.containsKey(format);

    return Material(
      child: InkWell(
        onTap: hasUrl && !isDownloading ? () => _downloadFormat(format) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDownloading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (hasUrl)
                Icon(Icons.chevron_right, color: color)
              else
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the export dialog
Future<void> showInvoiceExportDialog(
  BuildContext context,
  InvoiceModel invoice, {
  VoidCallback? onExportComplete,
}) {
  return showDialog(
    context: context,
    builder: (context) => InvoiceExportDialog(
      invoice: invoice,
      onExportComplete: onExportComplete,
    ),
  );
}

/// Alternative: Simple function for downloading all formats
Future<void> downloadInvoiceAllFormats(
  InvoiceModel invoice, {
  required VoidCallback onSuccess,
  required Function(String error) onError,
}) async {
  final client = InvoiceServiceClient();

  try {
    logger.i('Starting invoice export: ${invoice.invoiceNumber}');

    // Build invoice data
    final invoiceData = {
      'invoiceNumber': invoice.invoiceNumber,
      'invoiceId': invoice.id,
      'createdAt': invoice.createdAt.toIso8601String(),
      'dueDate': invoice.dueDate.toIso8601String(),
      'items': invoice.items
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'description': item.description ?? '',
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'vatRate': item.vatRate,
                'total': item.total,
              })
          .toList(),
      'currency': invoice.currency,
      'subtotal': invoice.subtotal,
      'totalVat': invoice.totalVat,
      'discount': invoice.discount ?? 0,
      'total': invoice.total,
      'businessName': invoice.businessName,
      'businessAddress': invoice.businessAddress ?? '',
      'clientName': invoice.clientName,
      'clientEmail': invoice.clientEmail,
      'clientAddress': invoice.clientAddress ?? '',
      'notes': invoice.notes ?? '',
      'status': invoice.status,
    };

    // Export all formats
    final urls = await client.exportInvoiceAllFormats(invoiceData);

    logger.i('Export successful. Generated ${urls.length} formats');

    // Open PDF by default
    if (urls.containsKey('pdf')) {
      await client.openUrl(urls['pdf']!);
    }

    onSuccess();
  } catch (e) {
    logger.e('Export failed: $e');

    try {
      // Fallback to local PDF
      logger.i('Attempting local PDF fallback');
      await LocalPdfGenerator.generateInvoicePdf(invoice);
      onSuccess();
    } catch (fallbackError) {
      logger.e('Fallback failed: $fallbackError');
      onError('Failed to export invoice: $fallbackError');
    }
  }
}
