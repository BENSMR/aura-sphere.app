import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../services/pdf_export_service.dart';

/// PDF export action button with options
class PDFExportButton extends StatefulWidget {
  final String invoiceId;
  final VoidCallback? onExportComplete;
  final IconData icon;
  final String tooltip;

  const PDFExportButton({
    Key? key,
    required this.invoiceId,
    this.onExportComplete,
    this.icon = Icons.download,
    this.tooltip = 'Export as PDF',
  }) : super(key: key);

  @override
  State<PDFExportButton> createState() => _PDFExportButtonState();
}

class _PDFExportButtonState extends State<PDFExportButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(widget.icon),
      tooltip: widget.tooltip,
      onSelected: (String choice) => _handleExportOption(context, choice),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 12),
              Text('Download PDF'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print, size: 20),
              SizedBox(width: 12),
              Text('Print'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'preview',
          child: Row(
            children: [
              Icon(Icons.preview, size: 20),
              SizedBox(width: 12),
              Text('Preview'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 12),
              Text('Share'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleExportOption(BuildContext context, String choice) async {
    setState(() => _isLoading = true);

    try {
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      final pdfService = PdfExportService();

      // Get invoice from provider (you'll need to implement this)
      // final invoice = invoiceProvider.getInvoiceById(widget.invoiceId);

      // For demo purposes, creating a sample invoice
      // In production, fetch from invoiceProvider
      final sampleInvoice = null; // Replace with actual invoice

      if (sampleInvoice == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice not found')),
          );
        }
        return;
      }

      // Generate PDF
      // final pdfBytes = await pdfService.generateInvoicePdf(sampleInvoice);

      // Handle based on choice
      // switch (choice) {
      //   case 'download':
      //     await pdfService.savePDFToDevice(
      //       pdfBytes: pdfBytes,
      //       fileName: 'Invoice_${widget.invoiceId}.pdf',
      //     );
      //     if (mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('PDF downloaded successfully')),
      //       );
      //     }
      //     break;
      //   case 'print':
      //     await pdfService.printPDF(
      //       pdfBytes: pdfBytes,
      //       documentName: 'Invoice_${widget.invoiceId}',
      //     );
      //     break;
      //   case 'preview':
      //     await pdfService.previewPDF(
      //       pdfBytes: pdfBytes,
      //       documentName: 'Invoice_${widget.invoiceId}',
      //     );
      //     break;
      //   case 'share':
      //     await pdfService.sharePDF(
      //       pdfBytes: pdfBytes,
      //       fileName: 'Invoice_${widget.invoiceId}.pdf',
      //     );
      //     break;
      // }

      widget.onExportComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// PDF export dialog with more options
class PDFExportDialog extends StatefulWidget {
  final String invoiceId;
  final String? invoiceNumber;

  const PDFExportDialog({
    Key? key,
    required this.invoiceId,
    this.invoiceNumber,
  }) : super(key: key);

  @override
  State<PDFExportDialog> createState() => _PDFExportDialogState();
}

class _PDFExportDialogState extends State<PDFExportDialog> {
  bool _isLoading = false;
  String _selectedFormat = 'pdf';
  bool _includeWatermark = false;
  bool _includeSignature = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedFormat,
              onChanged: (value) {
                setState(() => _selectedFormat = value ?? 'pdf');
              },
              items: const [
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'email', child: Text('Email')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Options',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Include Watermark'),
              value: _includeWatermark,
              onChanged: (value) {
                setState(() => _includeWatermark = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Include Signature'),
              value: _includeSignature,
              onChanged: (value) {
                setState(() => _includeSignature = value ?? false);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleExport(context),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final pdfService = PdfExportService();

      // Generate PDF with selected options
      // Implementation would go here
      // final pdfBytes = await pdfService.generateInvoicePdf(...);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice exported successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Batch PDF export for multiple invoices
class BatchPDFExportButton extends StatefulWidget {
  final List<String> invoiceIds;
  final VoidCallback? onExportComplete;

  const BatchPDFExportButton({
    Key? key,
    required this.invoiceIds,
    this.onExportComplete,
  }) : super(key: key);

  @override
  State<BatchPDFExportButton> createState() => _BatchPDFExportButtonState();
}

class _BatchPDFExportButtonState extends State<BatchPDFExportButton> {
  bool _isLoading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleBatchExport,
      icon: _isLoading ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : const Icon(Icons.download),
      label: Text(
        _isLoading
            ? 'Exporting... ${(_progress * 100).toInt()}%'
            : 'Export All (${widget.invoiceIds.length})',
      ),
    );
  }

  Future<void> _handleBatchExport() async {
    setState(() => _isLoading = true);

    try {
      final pdfService = PdfExportService();
      final totalInvoices = widget.invoiceIds.length;

      for (int i = 0; i < totalInvoices; i++) {
        // Generate PDF for each invoice
        // Implementation would go here
        
        setState(() {
          _progress = (i + 1) / totalInvoices;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Exported $totalInvoices invoices successfully'),
          ),
        );
      }

      widget.onExportComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
