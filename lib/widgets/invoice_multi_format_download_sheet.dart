import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import '../services/invoice_multi_format_export_service.dart';
import '../utils/simple_logger.dart';

/// Enhanced modal bottom sheet for multi-format invoice downloads
class InvoiceMultiFormatDownloadSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final String businessName;
  final String businessAddress;
  final String? userLogoUrl;
  final String? notes;
  final VoidCallback? onDownloadComplete;

  const InvoiceMultiFormatDownloadSheet({
    Key? key,
    required this.invoice,
    required this.businessName,
    required this.businessAddress,
    this.userLogoUrl,
    this.notes,
    this.onDownloadComplete,
  }) : super(key: key);

  @override
  State<InvoiceMultiFormatDownloadSheet> createState() =>
      _InvoiceMultiFormatDownloadSheetState();
}

class _InvoiceMultiFormatDownloadSheetState
    extends State<InvoiceMultiFormatDownloadSheet> {
  final _exportService = InvoiceMultiFormatExportService();
  String? _downloadingFormat;
  String? _errorMessage;
  Map<String, String>? _exportUrls;

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
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _errorMessage = null),
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
                  _buildFormatOption(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: 'Download as PDF',
                    subtitle: 'Professional invoice document',
                    format: 'pdf',
                    isLoading: _downloadingFormat == 'pdf',
                  ),
                  Divider(height: 1),
                  _buildFormatOption(
                    context,
                    icon: Icons.image,
                    title: 'Download as PNG',
                    subtitle: 'Invoice screenshot/image',
                    format: 'png',
                    isLoading: _downloadingFormat == 'png',
                  ),
                  Divider(height: 1),
                  _buildFormatOption(
                    context,
                    icon: Icons.description,
                    title: 'Download as DOCX',
                    subtitle: 'Microsoft Word document',
                    format: 'docx',
                    isLoading: _downloadingFormat == 'docx',
                  ),
                  Divider(height: 1),
                  _buildFormatOption(
                    context,
                    icon: Icons.table_view,
                    title: 'Download as CSV',
                    subtitle: 'Spreadsheet data format',
                    format: 'csv',
                    isLoading: _downloadingFormat == 'csv',
                  ),
                  Divider(height: 1),
                  _buildFormatOption(
                    context,
                    icon: Icons.folder_zip,
                    title: 'Download ALL (ZIP)',
                    subtitle: 'All formats in one file',
                    format: 'zip',
                    isLoading: _downloadingFormat == 'zip',
                  ),
                  if (_exportUrls != null) ...[
                    Divider(height: 1),
                    _buildExportSummary(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
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
          ? () => _downloadFormat(format)
          : null,
    );
  }

  Widget _buildExportSummary(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ All exports generated successfully!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 12),
          ..._exportUrls!.entries.map((e) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _downloadFormat(String format) async {
    setState(() {
      _downloadingFormat = format;
      _errorMessage = null;
    });

    try {
      logger.info('Starting download', {
        'format': format,
        'invoiceId': widget.invoice.id,
      });

      String? url;

      switch (format) {
        case 'pdf':
          url = await _exportService.exportPdf(
            invoice: widget.invoice,
            businessName: widget.businessName,
            businessAddress: widget.businessAddress,
            userLogoUrl: widget.userLogoUrl,
            notes: widget.notes,
          );
          break;
        case 'png':
          url = await _exportService.exportPng(
            invoice: widget.invoice,
            businessName: widget.businessName,
            businessAddress: widget.businessAddress,
            userLogoUrl: widget.userLogoUrl,
            notes: widget.notes,
          );
          break;
        case 'docx':
          url = await _exportService.exportDocx(
            invoice: widget.invoice,
            businessName: widget.businessName,
            businessAddress: widget.businessAddress,
            userLogoUrl: widget.userLogoUrl,
            notes: widget.notes,
          );
          break;
        case 'csv':
          url = await _exportService.exportCsv(
            invoice: widget.invoice,
            businessName: widget.businessName,
            businessAddress: widget.businessAddress,
            userLogoUrl: widget.userLogoUrl,
            notes: widget.notes,
          );
          break;
        case 'zip':
          url = await _exportService.exportZip(
            invoice: widget.invoice,
            businessName: widget.businessName,
            businessAddress: widget.businessAddress,
            userLogoUrl: widget.userLogoUrl,
            notes: widget.notes,
          );
          break;
        default:
          throw Exception('Unknown format: $format');
      }

      if (mounted) {
        // Get all URLs for summary
        final allUrls = await _exportService.getExportUrls(
          invoice: widget.invoice,
          businessName: widget.businessName,
          businessAddress: widget.businessAddress,
          userLogoUrl: widget.userLogoUrl,
          notes: widget.notes,
        );

        setState(() {
          _exportUrls = allUrls;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Downloaded as ${format.toUpperCase()}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open all',
              onPressed: () {
                // Could launch URL here or show another dialog
              },
            ),
          ),
        );

        widget.onDownloadComplete?.call();
      }
    } catch (e) {
      logger.error('Download failed', {
        'format': format,
        'error': e.toString(),
      });

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
}

/// Show multi-format invoice download sheet
void showInvoiceMultiFormatDownloadSheet(
  BuildContext context,
  InvoiceModel invoice, {
  required String businessName,
  required String businessAddress,
  String? userLogoUrl,
  String? notes,
  VoidCallback? onDownloadComplete,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => InvoiceMultiFormatDownloadSheet(
      invoice: invoice,
      businessName: businessName,
      businessAddress: businessAddress,
      userLogoUrl: userLogoUrl,
      notes: notes,
      onDownloadComplete: onDownloadComplete,
    ),
  );
}
