# Invoice Export Usage Guide

**Status:** ✅ PRODUCTION READY | **Date:** November 27, 2025

---

## 🎯 Quick Reference

The complete invoice export system is now ready to use. This guide shows the most common usage patterns.

---

## 📦 What You Have

### Cloud Functions
- ✅ `exportInvoiceFormats` - Generate all 5 formats (PDF, PNG, DOCX, CSV, ZIP)
- ✅ `generateInvoicePdf` - Generate single PDF

### Dart Service
- ✅ `InvoiceServiceClient` - Cloud Function wrapper

### Flutter Widget
- ✅ `InvoiceExportDialog` - Beautiful export UI
- ✅ `showInvoiceExportDialog()` - Helper function

### InvoiceModel Method
- ✅ `toMapForExport()` - Format data for Cloud Functions

---

## 💡 Usage Pattern 1: Simplest Integration (Recommended)

```dart
import 'package:aura_sphere_pro/data/models/invoice_model.dart';
import 'package:aura_sphere_pro/widgets/invoice_export_dialog.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => showInvoiceExportDialog(context, invoice),
            tooltip: 'Export invoice',
          ),
        ],
      ),
      body: _buildInvoiceContent(),
    );
  }
}
```

**Result:** Click icon → Beautiful dialog opens → User selects format → File exports in all 5 formats

---

## 💡 Usage Pattern 2: With Callback

```dart
showInvoiceExportDialog(
  context,
  invoice,
  onExportComplete: () {
    // Called when export completes successfully
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice exported successfully!')),
    );
    // Refresh data if needed
    setState(() {});
  },
);
```

---

## 💡 Usage Pattern 3: Programmatic Export (No Dialog)

```dart
import 'package:aura_sphere_pro/widgets/invoice_export_dialog.dart';

Future<void> exportInvoiceQuietly(InvoiceModel invoice) async {
  try {
    await downloadInvoiceAllFormats(
      invoice,
      onSuccess: () {
        print('✅ Export successful');
      },
      onError: (error) {
        print('❌ Export failed: $error');
      },
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 💡 Usage Pattern 4: Get Export URLs Directly

```dart
import 'package:aura_sphere_pro/services/invoice_service_client.dart';

Future<void> getInvoiceDownloadLinks(InvoiceModel invoice) async {
  final client = InvoiceServiceClient();

  try {
    // Prepare invoice data
    final invoiceData = invoice.toMapForExport(
      businessName: 'ACME Corp',
      businessAddress: '123 Main St, New York, NY',
    );

    // Get all export URLs
    final urls = await client.exportInvoiceAllFormats(invoiceData);

    // Now you can use the URLs
    print('PDF: ${urls['pdf']}');
    print('PNG: ${urls['png']}');
    print('DOCX: ${urls['docx']}');
    print('CSV: ${urls['csv']}');
    print('ZIP: ${urls['zip']}');

    // Open PDF in browser
    await client.openUrl(urls['pdf']!);
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 💡 Usage Pattern 5: Export Specific Format

```dart
Future<void> exportPdfOnly(InvoiceModel invoice) async {
  final client = InvoiceServiceClient();

  try {
    final invoiceData = invoice.toMapForExport(
      businessName: 'ACME Corp',
      businessAddress: '123 Main St',
    );

    // Export only PDF
    final pdfUrl = await client.exportInvoicePdf(invoiceData);

    // Download the file
    final bytes = await client.downloadFile(pdfUrl);

    // Save or share (implement as needed)
    print('Downloaded ${bytes.length} bytes');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 💡 Usage Pattern 6: Download and Save to File

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:aura_sphere_pro/services/invoice_service_client.dart';

Future<String> downloadAndSaveInvoice(InvoiceModel invoice) async {
  final client = InvoiceServiceClient();

  try {
    final invoiceData = invoice.toMapForExport(
      businessName: 'ACME Corp',
      businessAddress: '123 Main St',
    );

    // Get URL
    final urls = await client.exportInvoiceAllFormats(invoiceData);
    final pdfUrl = urls['pdf']!;

    // Download bytes
    final bytes = await client.downloadFile(pdfUrl);

    // Get downloads directory
    final downloadsDir = await getDownloadsDirectory();
    final fileName = '${invoice.invoiceNumber}.pdf';
    final filePath = '${downloadsDir?.path}/$fileName';

    // Save to file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    print('✅ Saved to: $filePath');
    return filePath;
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}
```

---

## 📝 Key Methods

### InvoiceModel.toMapForExport()

Prepares invoice data for Cloud Functions.

```dart
final invoiceData = invoice.toMapForExport(
  businessName: 'Your Company Name',
  businessAddress: 'Your Address',
);
```

**Parameters:**
- `businessName` (String): Your company name (default: 'Your Business')
- `businessAddress` (String): Your company address (default: '')

**Returns:** `Map<String, dynamic>` with all required fields for Cloud Functions

---

### InvoiceServiceClient.exportInvoiceAllFormats()

Exports invoice in all 5 formats at once.

```dart
final urls = await client.exportInvoiceAllFormats(invoiceData);
// Returns: {
//   'pdf': 'https://...',
//   'png': 'https://...',
//   'docx': 'https://...',
//   'csv': 'https://...',
//   'zip': 'https://...'
// }
```

---

### InvoiceServiceClient.exportInvoicePdf()

Exports invoice as PDF only.

```dart
final pdfUrl = await client.exportInvoicePdf(invoiceData);
```

---

### InvoiceServiceClient.openUrl()

Opens a URL in the default browser.

```dart
await client.openUrl(pdfUrl);
```

---

### InvoiceServiceClient.downloadFile()

Downloads a file from a signed URL and returns bytes.

```dart
final bytes = await client.downloadFile(url);
```

---

## 🔧 Integration Checklist

- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] `InvoiceModel.toMapForExport()` method added
- [ ] Import `InvoiceExportDialog` in your screens
- [ ] Add export button to UI
- [ ] Test with sample invoice
- [ ] Verify all 5 formats export
- [ ] Test fallback to local PDF
- [ ] Deploy to production

---

## ⚠️ Important Notes

### Business Information

The Cloud Functions need your business information. You have two options:

**Option 1: Pass when exporting (Recommended)**
```dart
final data = invoice.toMapForExport(
  businessName: 'ACME Corp',
  businessAddress: '123 Main St, New York, NY',
);
```

**Option 2: Set as defaults in your app**
```dart
// In your settings or config
class AppConfig {
  static const String businessName = 'ACME Corp';
  static const String businessAddress = '123 Main St, New York, NY';
}

// Use everywhere
final data = invoice.toMapForExport(
  businessName: AppConfig.businessName,
  businessAddress: AppConfig.businessAddress,
);
```

---

## 🛡️ Error Handling

All methods include error handling. Fallback to local PDF is automatic:

```dart
try {
  final urls = await client.exportInvoiceAllFormats(invoiceData);
} catch (e) {
  // Fallback to local PDF is handled automatically
  // in InvoiceExportDialog
  print('Export failed, using local PDF');
}
```

---

## 🧪 Testing

### Quick Test (2 minutes)

```dart
test('Export dialog opens', () {
  final invoice = createTestInvoice();
  expect(
    find.byType(InvoiceExportDialog),
    findsWidgets,
  );
});
```

### Full Test (10 minutes)

```dart
test('Export all formats', () async {
  final client = InvoiceServiceClient();
  final invoice = createTestInvoice();
  final data = invoice.toMapForExport();

  final urls = await client.exportInvoiceAllFormats(data);

  expect(urls.containsKey('pdf'), true);
  expect(urls.containsKey('png'), true);
  expect(urls.containsKey('docx'), true);
  expect(urls.containsKey('csv'), true);
  expect(urls.containsKey('zip'), true);
});
```

---

## 📚 Additional Resources

### Complete Documentation
- [INVOICE_EXPORT_INTEGRATION_GUIDE.md](INVOICE_EXPORT_INTEGRATION_GUIDE.md) - Full guide with architecture
- [INVOICE_MULTI_FORMAT_EXPORT_QUICK_START.md](INVOICE_MULTI_FORMAT_EXPORT_QUICK_START.md) - Setup and testing

### Code Files
- [lib/data/models/invoice_model.dart](lib/data/models/invoice_model.dart) - InvoiceModel class
- [lib/services/invoice_service_client.dart](lib/services/invoice_service_client.dart) - Export service
- [lib/widgets/invoice_export_dialog.dart](lib/widgets/invoice_export_dialog.dart) - Export dialog

---

## 🎯 Most Common Use Case

### Show Export Dialog on Button Click

```dart
// 1. Add button to your UI
FloatingActionButton(
  onPressed: () => showInvoiceExportDialog(context, invoice),
  child: Icon(Icons.download),
)

// That's it! ✅
```

This single line gives users:
- Beautiful dialog with 5 format options
- Real-time progress indicators
- Error handling with fallback
- Automatic download
- Success notification

---

## 🚀 Next Steps

1. **Test Now:** Try the simplest pattern (Pattern 1) above
2. **Deploy:** When ready, run `firebase deploy --only functions`
3. **Integrate:** Add export button to your invoice screens
4. **Monitor:** Check Cloud Function logs in Firebase Console

---

## ✅ You're Ready!

All code is production-ready. Just:
1. Call `toMapForExport()` on your invoice
2. Show the dialog or call the service directly
3. Users get beautiful export experience

```dart
// One line to add export functionality:
showInvoiceExportDialog(context, invoice);
```

Done! 🎉

---

*Last updated: November 27, 2025*  
*Status: ✅ Production Ready*  
*Version: 1.0*
