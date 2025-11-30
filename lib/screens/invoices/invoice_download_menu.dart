// lib/screens/invoices/invoice_download_menu.dart
import 'package:flutter/material.dart';
import '../../data/models/invoice_model.dart';
import '../../services/invoice_service_client.dart';
import '../../utils/simple_logger.dart';

class InvoiceDownloadMenu {
  static void show(
    BuildContext context,
    InvoiceModel invoice,
    Map<String, dynamic> invoiceJson,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Export Invoice',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text('Download as PDF'),
                    subtitle: Text('Professional document'),
                    onTap: () => _downloadFormat(
                      ctx,
                      invoice,
                      invoiceJson,
                      'PDF',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: Colors.blue),
                    title: Text('Download as DOCX'),
                    subtitle: Text('Word document'),
                    onTap: () => _downloadFormat(
                      ctx,
                      invoice,
                      invoiceJson,
                      'DOCX',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.image_outlined, color: Colors.orange),
                    title: Text('Download as PNG'),
                    subtitle: Text('Screenshot image'),
                    onTap: () => _downloadFormat(
                      ctx,
                      invoice,
                      invoiceJson,
                      'PNG',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.table_view, color: Colors.green),
                    title: Text('Download as CSV'),
                    subtitle: Text('Spreadsheet data'),
                    onTap: () => _downloadFormat(
                      ctx,
                      invoice,
                      invoiceJson,
                      'CSV',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.folder_zip, color: Colors.purple),
                    title: Text('Download ALL (ZIP)'),
                    subtitle: Text('All formats bundled'),
                    onTap: () => _downloadFormat(
                      ctx,
                      invoice,
                      invoiceJson,
                      'ZIP',
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _downloadFormat(
    BuildContext context,
    InvoiceModel invoice,
    Map<String, dynamic> invoiceJson,
    String format,
  ) async {
    Navigator.pop(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Exporting as $format...'),
          ],
        ),
      ),
    );

    try {
      final client = InvoiceServiceClient();
      
      // Export all formats
      final urls = await client.exportInvoiceAllFormats(invoiceJson);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Get the requested format URL
      final filename = invoiceJson['invoiceNumber'] ?? 'invoice';
      String? downloadUrl;

      switch (format) {
        case 'PDF':
          downloadUrl = urls['$filename.pdf'];
          break;
        case 'DOCX':
          downloadUrl = urls['$filename.docx'];
          break;
        case 'PNG':
          downloadUrl = urls['$filename.png'];
          break;
        case 'CSV':
          downloadUrl = urls['$filename.csv'];
          break;
        case 'ZIP':
          downloadUrl = urls['$filename.zip'];
          break;
      }

      if (downloadUrl != null) {
        await client.openUrl(downloadUrl);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$format download started'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('URL not found for $format');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      SimpleLogger.e('Export error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
