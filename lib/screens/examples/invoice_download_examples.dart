import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import '../widgets/invoice_download_sheet.dart';
import '../services/invoice_service.dart';

/// Example: Basic download button in invoice list
class InvoiceListItemWithDownload extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceListItemWithDownload({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(invoice.invoiceNumber ?? 'Invoice'),
      subtitle: Text(invoice.clientName),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.download),
                SizedBox(width: 12),
                Text('Download'),
              ],
            ),
            onTap: () => showInvoiceDownloadSheet(context, invoice),
          ),
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 12),
                Text('Share'),
              ],
            ),
            onTap: () => _shareInvoice(context),
          ),
        ],
      ),
    );
  }

  void _shareInvoice(BuildContext context) {
    // TODO: Implement sharing
  }
}

/// Example: Invoice detail screen with download button
class InvoiceDetailScreenExample extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreenExample({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => showInvoiceDownloadSheet(context, invoice),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Invoice preview
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice ${invoice.invoiceNumber}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      Text('Client: ${invoice.clientName}'),
                      Text('Email: ${invoice.clientEmail}'),
                      SizedBox(height: 16),
                      Text(
                        'Total: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Items preview
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  ...invoice.items.map((item) => ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text('${invoice.currency} ${item.total.toStringAsFixed(2)}'),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInvoiceDownloadSheet(context, invoice),
        label: Text('Download'),
        icon: Icon(Icons.download),
      ),
    );
  }
}

/// Example: Custom download function (called from user code)
Future<void> downloadInvoicePdf(
  BuildContext context,
  InvoiceModel invoice,
  InvoiceService invoiceService,
) async {
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    // Generate PDF
    final pdfBytes = await invoiceService.generateLocalPdf(invoice);

    // Close loading dialog
    Navigator.pop(context);

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ PDF generated successfully'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Download Options',
          onPressed: () => showInvoiceDownloadSheet(context, invoice),
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Example: Batch export (multiple invoices)
Future<void> batchExportInvoices(
  List<InvoiceModel> invoices,
  InvoiceExportService exportService,
) async {
  for (final invoice in invoices) {
    try {
      await exportService.exportCsv(invoice);
      print('✅ Exported ${invoice.invoiceNumber}');
    } catch (e) {
      print('❌ Failed to export ${invoice.invoiceNumber}: $e');
    }
  }
}

/// Example: Using from invoice service directly
class InvoiceService {
  // Existing methods...

  /// Download invoice in specified format
  static Future<void> download(
    InvoiceModel invoice, {
    required String format,
  }) async {
    final exportService = InvoiceExportService();

    try {
      switch (format) {
        case 'pdf':
          // Implement PDF download
          break;
        case 'csv':
          await exportService.exportCsv(invoice);
          break;
        case 'json':
          await exportService.exportJson(invoice);
          break;
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      rethrow;
    }
  }
}
