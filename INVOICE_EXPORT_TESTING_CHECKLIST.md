# ✅ Invoice Export System - Testing Checklist

**Date:** November 27, 2025  
**Status:** READY FOR TESTING  
**Scope:** Cloud Functions, Firebase Storage, Flutter Integration, Offline Fallbacks

---

## 📋 Table of Contents

1. [Pre-Deployment Verification](#pre-deployment-verification)
2. [Deploy Cloud Function](#deploy-cloud-function)
3. [Create Sample Invoice Data](#create-sample-invoice-data)
4. [Test Cloud Function Callable](#test-cloud-function-callable)
5. [Verify Storage Entries](#verify-storage-entries)
6. [Test File Downloads](#test-file-downloads)
7. [Test Offline Fallback](#test-offline-fallback)
8. [Monitor Performance](#monitor-performance)
9. [Security Testing](#security-testing)
10. [Load Testing](#load-testing)
11. [Production Checklist](#production-checklist)

---

## Pre-Deployment Verification

### Code Quality Check

```bash
# In functions directory
cd functions

# Check TypeScript compilation
npm run build

# Expected output:
# ✅ Successfully compiled with no errors
# ✅ exportInvoiceFormats.js (26KB)
# ✅ generateInvoicePdf.js (16KB)
```

### Output Verification

```bash
# List compiled files
ls -lh lib/

# Expected output should show:
# -rw-r--r-- 26K Nov 27 12:00 exportInvoiceFormats.js
# -rw-r--r-- 16K Nov 27 12:00 generateInvoicePdf.js
```

### Dependency Check

```bash
# Verify all dependencies installed
npm list puppeteer docx adm-zip @types/adm-zip

# Expected output:
# puppeteer@21.11.0
# docx@9.5.1
# adm-zip@0.5.10
# @types/adm-zip@0.5.7
```

### Configuration Verification

```bash
# Check runtime config in exportInvoiceFormats.ts
grep -A2 "runWith({" functions/src/invoices/exportInvoiceFormats.ts

# Expected output:
# runWith({
#   memory: '2GB',
#   timeoutSeconds: 300,
# })
```

✅ **All checks passing?** → Continue to deployment

---

## Deploy Cloud Function

### Step 1: Prepare Environment

```bash
# Navigate to project root
cd /workspaces/aura-sphere-pro

# Verify Firebase is configured
firebase projects:list

# Expected: Shows your Firebase project ID
```

### Step 2: Deploy Functions

```bash
# Deploy only the invoice export functions
cd functions
firebase deploy --only functions:exportInvoiceFormats --region us-central1

# Expected output:
# ✔  functions[us-central1-exportInvoiceFormats] Deployed successfully
# Function URL: https://us-central1-<PROJECT_ID>.cloudfunctions.net/exportInvoiceFormats
```

```bash
# Also deploy the PDF function (if not already deployed)
firebase deploy --only functions:generateInvoicePdf --region us-central1

# Expected output:
# ✔  functions[us-central1-generateInvoicePdf] Deployed successfully
```

### Step 3: Verify Deployment

```bash
# List deployed functions
firebase functions:list

# Expected output showing both functions:
# Function                       Status    Trigger
# exportInvoiceFormats           OK        HTTPS (Callable)
# generateInvoicePdf             OK        HTTPS (Callable)
```

### Step 4: Check Function Logs

```bash
# View recent logs (should be empty or minimal)
firebase functions:log --limit=10

# Expected: No errors, just deployment messages
```

✅ **Functions deployed successfully?** → Continue to sample data creation

---

## Create Sample Invoice Data

### Method 1: Firebase Emulator (Local Testing)

```bash
# Start the emulator
firebase emulators:start --import=./emulator-data

# In separate terminal, add sample data to emulator
# This uses the Firestore emulator UI at http://localhost:4000
```

### Method 2: Firestore Console (Cloud Testing)

#### Step 1: Create Sample Invoice Document

In Firebase Console:
1. Go to Firestore Database
2. Create collection: `invoices`
3. Add new document with ID: `test-invoice-001`

```json
{
  "userId": "test-user-001",
  "invoiceNumber": "INV-2025-001",
  "clientName": "Acme Corporation",
  "clientEmail": "billing@acme.com",
  "clientAddress": "123 Business Ave, New York, NY 10001",
  "subtotal": 10000,
  "tax": 2000,
  "total": 12000,
  "discount": 500,
  "currency": "USD",
  "taxRate": 20,
  "status": "draft",
  "dueDate": {
    "_type": "timestamp",
    "value": "2025-12-31T00:00:00Z"
  },
  "createdAt": {
    "_type": "timestamp",
    "value": "2025-11-27T00:00:00Z"
  },
  "pdfUrl": "",
  "notes": "Sample invoice for testing multi-format export",
  "items": [
    {
      "id": "item-1",
      "description": "Professional Services - Consultation",
      "quantity": 10,
      "unitPrice": 500,
      "total": 5000
    },
    {
      "id": "item-2",
      "description": "Development Work - Implementation",
      "quantity": 5,
      "unitPrice": 1000,
      "total": 5000
    }
  ]
}
```

#### Step 2: Verify Document Created

```bash
# Query via Firebase CLI
firebase firestore:get invoices/test-invoice-001

# Expected output:
# ✔  SUCCESS: Retrieved document invoices/test-invoice-001
# {
#   userId: "test-user-001",
#   invoiceNumber: "INV-2025-001",
#   ...
# }
```

### Method 3: Create via Dart (App Testing)

```dart
// In your Flutter app, create test data programmatically
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createTestInvoice() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('User not authenticated');
    return;
  }

  final invoice = {
    'userId': user.uid,
    'invoiceNumber': 'TEST-INV-001',
    'clientName': 'Test Client',
    'clientEmail': 'test@example.com',
    'clientAddress': '456 Test Street',
    'subtotal': 5000.00,
    'tax': 1000.00,
    'total': 6000.00,
    'discount': 0.00,
    'currency': 'USD',
    'taxRate': 20.0,
    'status': 'draft',
    'dueDate': DateTime.now().add(Duration(days: 30)),
    'createdAt': DateTime.now(),
    'notes': 'Test invoice for export system',
    'items': [
      {
        'id': '1',
        'description': 'Test Service',
        'quantity': 5,
        'unitPrice': 1000,
        'total': 5000,
      }
    ],
  };

  try {
    await FirebaseFirestore.instance
      .collection('invoices')
      .add(invoice);
    print('✅ Test invoice created');
  } catch (e) {
    print('❌ Error creating test invoice: $e');
  }
}
```

---

## Test Cloud Function Callable

### Method 1: Firebase Emulator

```bash
# Start emulator with all services
firebase emulators:start

# In another terminal, run test
```

### Method 2: Direct HTTPS Callable (Dart/Flutter)

#### Test 1: Simple Export (All Formats)

```dart
// lib/screens/test_screens/invoice_export_test_screen.dart

import 'package:firebase_functions/firebase_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceExportTestScreen extends StatefulWidget {
  @override
  State<InvoiceExportTestScreen> createState() => _InvoiceExportTestScreenState();
}

class _InvoiceExportTestScreenState extends State<InvoiceExportTestScreen> {
  final _functions = FirebaseFunctions.instance;
  String? _result;
  String? _error;
  bool _isLoading = false;

  Future<void> testExportAllFormats() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Get test invoice from Firestore
      final invoiceDoc = await FirebaseFirestore.instance
        .collection('invoices')
        .doc('test-invoice-001')
        .get();

      if (!invoiceDoc.exists) {
        throw Exception('Test invoice not found');
      }

      final invoiceData = invoiceDoc.data() as Map<String, dynamic>;

      // Convert to export format
      final exportData = {
        'invoiceNumber': invoiceData['invoiceNumber'],
        'invoiceId': invoiceDoc.id,
        'createdAt': (invoiceData['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String(),
        'dueDate': (invoiceData['dueDate'] as Timestamp)
          .toDate()
          .toIso8601String(),
        'items': invoiceData['items'] ?? [],
        'currency': invoiceData['currency'] ?? 'USD',
        'subtotal': invoiceData['subtotal'] ?? 0,
        'totalVat': invoiceData['tax'] ?? 0,
        'discount': invoiceData['discount'] ?? 0,
        'total': invoiceData['total'] ?? 0,
        'businessName': 'Test Business',
        'businessAddress': '789 Test Blvd, Test City',
        'clientName': invoiceData['clientName'] ?? '',
        'clientEmail': invoiceData['clientEmail'] ?? '',
        'clientAddress': invoiceData['clientAddress'] ?? '',
        'notes': invoiceData['notes'] ?? '',
        'status': invoiceData['status'] ?? 'draft',
        'taxRate': invoiceData['taxRate'] ?? 20,
        'linkedExpenseIds': invoiceData['linkedExpenseIds'] ?? [],
      };

      print('[TEST] Calling exportInvoiceFormats with data: $exportData');

      // Call Cloud Function
      final callable = _functions.httpsCallable('exportInvoiceFormats');
      final result = await callable.call(exportData);

      print('[TEST] ✅ Success: ${result.data}');

      setState(() {
        _result = 'Export successful!\n\n${jsonEncode(result.data)}';
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      print('[TEST] ❌ Function error: ${e.code} - ${e.message}');
      setState(() {
        _error = 'Error: ${e.code}\nMessage: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      print('[TEST] ❌ Exception: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Export Test')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : testExportAllFormats,
              child: Text(_isLoading ? 'Testing...' : 'Test Export All Formats'),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
            if (_error != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            if (_result != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result!,
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### Test 2: Test Individual Formats

```dart
Future<void> testExportFormat(String format) async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final invoiceDoc = await FirebaseFirestore.instance
      .collection('invoices')
      .doc('test-invoice-001')
      .get();

    final exportData = {
      // ... same as above
      'requestedFormats': [format], // Only request one format
    };

    final callable = _functions.httpsCallable('exportInvoiceFormats');
    final result = await callable.call(exportData);

    print('[TEST] ✅ Format $format exported successfully');
    setState(() {
      _result = 'Format $format:\n\n${jsonEncode(result.data)}';
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Error exporting $format: $e';
      _isLoading = false;
    });
  }
}
```

### Method 3: cURL (Command Line Testing)

```bash
# Get authentication token
TOKEN=$(gcloud auth application-default print-access-token)

# Call function with curl
curl -X POST \
  https://us-central1-aura-sphere-pro.cloudfunctions.net/exportInvoiceFormats \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoiceNumber": "INV-2025-001",
    "invoiceId": "test-invoice-001",
    "createdAt": "2025-11-27T00:00:00Z",
    "dueDate": "2025-12-31T00:00:00Z",
    "items": [
      {
        "id": "1",
        "name": "Service",
        "description": "Test Service",
        "quantity": 1,
        "unitPrice": 1000,
        "vatRate": 20,
        "total": 1000
      }
    ],
    "currency": "USD",
    "subtotal": 1000,
    "totalVat": 200,
    "discount": 0,
    "total": 1200,
    "businessName": "Test Business",
    "businessAddress": "123 Test St",
    "clientName": "Test Client",
    "clientEmail": "test@example.com",
    "clientAddress": "456 Client St",
    "notes": "Test",
    "status": "draft",
    "taxRate": 20,
    "linkedExpenseIds": []
  }'

# Expected output (on success):
# {
#   "result": {
#     "success": true,
#     "urls": {
#       "pdf": "https://storage.googleapis.com/...",
#       "png": "https://storage.googleapis.com/...",
#       "docx": "https://storage.googleapis.com/...",
#       "csv": "https://storage.googleapis.com/...",
#       "zip": "https://storage.googleapis.com/..."
#     },
#     "metadata": {
#       "filesGenerated": 5,
#       "totalSize": 512000,
#       "durationMs": 5234
#     }
#   }
# }
```

### Expected Test Results

✅ **Test 1: All Formats**
- Response: `{success: true, urls: {...}}`
- Duration: 5-8 seconds
- Memory: Should not exceed 1.5GB

✅ **Test 2: Individual Formats**
- PDF: ~300KB, 3-5 seconds
- CSV: ~50KB, <1 second
- DOCX: ~100KB, 2-3 seconds
- PNG: ~200KB, 3-5 seconds
- ZIP: ~400KB, 1-2 seconds

---

## Verify Storage Entries

### Check 1: Verify Path Structure

```bash
# List exports directory
gsutil ls -r gs://aura-sphere-pro/exports/

# Expected output:
# gs://aura-sphere-pro/exports/test-user-001/
# gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/
# gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.pdf
# gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.csv
# ...
```

### Check 2: Verify File Sizes

```bash
# Get file details
gsutil ls -lh gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/

# Expected output:
#          SIZE  TIME_CREATED                 NAME
#    250.5 KiB  2025-11-27T12:30:45Z  gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.pdf
#     50.3 KiB  2025-11-27T12:30:46Z  gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.csv
#    120.7 KiB  2025-11-27T12:30:47Z  gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.docx
#    180.2 KiB  2025-11-27T12:30:48Z  gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.png
#    450.8 KiB  2025-11-27T12:30:49Z  gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.zip
```

### Check 3: Verify File Integrity

```bash
# Download and check PDF
gsutil cp gs://aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.pdf /tmp/

# Verify PDF is valid
file /tmp/invoice.pdf
# Should output: PDF document, version 1.4

# Check file size
ls -lh /tmp/invoice.pdf
```

### Check 4: In Firebase Console

1. Go to Storage
2. Navigate to: `exports/test-user-001/INV-2025-001/`
3. Verify files are visible:
   - ✅ invoice.pdf
   - ✅ invoice.csv
   - ✅ invoice.docx
   - ✅ invoice.png
   - ✅ invoice.zip

✅ **All files present and correct size?** → Continue to download testing

---

## Test File Downloads

### Test 1: Download via Signed URL

```bash
# Get signed URL from Cloud Function response
# Example URL from earlier test result

PDF_URL="https://storage.googleapis.com/aura-sphere-pro/exports/test-user-001/INV-2025-001/invoice.pdf?X-Goog-Algorithm=..."

# Download and verify
curl -L "$PDF_URL" -o /tmp/test-invoice.pdf
file /tmp/test-invoice.pdf

# Expected:
# /tmp/test-invoice.pdf: PDF document, version 1.4
```

### Test 2: Open in Browser

```bash
# Print URLs for manual testing
echo "PDF:   $PDF_URL"
echo "CSV:   $CSV_URL"
echo "DOCX:  $DOCX_URL"
echo "PNG:   $PNG_URL"
echo "ZIP:   $ZIP_URL"

# Manually open each in browser:
# 1. Copy URL
# 2. Paste in browser
# 3. Should download file (not open/error)
```

### Test 3: Dart Download Implementation

```dart
Future<void> testDownloadFormat(String format, String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      print('✅ Successfully downloaded $format');
      print('   Size: ${response.bodyBytes.length} bytes');
      
      // Verify file type
      final headers = response.headers;
      final contentType = headers['content-type'] ?? 'unknown';
      print('   Content-Type: $contentType');
      
      // Save to device
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invoice.$format');
      await file.writeAsBytes(response.bodyBytes);
      print('   Saved to: ${file.path}');
    } else {
      print('❌ Download failed: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Test 4: Check Content Type

```bash
# Verify each file has correct MIME type

# PDF
curl -I "$PDF_URL" | grep -i content-type
# Expected: Content-Type: application/pdf

# CSV
curl -I "$CSV_URL" | grep -i content-type
# Expected: Content-Type: text/csv

# DOCX
curl -I "$DOCX_URL" | grep -i content-type
# Expected: Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document

# PNG
curl -I "$PNG_URL" | grep -i content-type
# Expected: Content-Type: image/png

# ZIP
curl -I "$ZIP_URL" | grep -i content-type
# Expected: Content-Type: application/zip
```

### Test Checklist

- [ ] PDF downloads and opens in PDF reader
- [ ] CSV downloads and opens in spreadsheet (Excel/Sheets)
- [ ] DOCX downloads and opens in Word
- [ ] PNG displays as image
- [ ] ZIP extracts and contains all 4 files
- [ ] Files are correct size (not corrupted)
- [ ] Content is readable and correct

✅ **All downloads successful?** → Continue to offline testing

---

## Test Offline Fallback

### Setup: Local PDF Generation

Ensure [LocalPdfGenerator](lib/utils/local_pdf_generator.dart) is implemented and working.

### Test 1: Simulate Network Error

```dart
// In invoice_export_dialog.dart or export service

Future<void> testOfflineFallback(InvoiceModel invoice) async {
  try {
    // Step 1: Try cloud export (this will fail)
    print('[OFFLINE_TEST] Attempting cloud export...');
    
    final data = invoice.toMapForExport(
      businessName: 'Test Business',
      businessAddress: '123 Test St',
    );

    // Simulate network timeout
    final result = await Future.delayed(Duration(seconds: 2))
      .then((_) => throw 'Network timeout');

    // This won't execute
  } on Exception catch (e) {
    print('[OFFLINE_TEST] ❌ Cloud export failed: $e');
    print('[OFFLINE_TEST] Fallback: Generating PDF locally...');

    // Step 2: Fall back to local generation
    try {
      final pdfBytes = await LocalPdfGenerator.generateInvoicePdf(
        invoice: invoice,
        businessName: 'Test Business',
        businessAddress: '123 Test St',
      );

      print('[OFFLINE_TEST] ✅ Local PDF generated: ${pdfBytes.length} bytes');

      // Step 3: Save to device
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/offline-invoice.pdf');
      await file.writeAsBytes(pdfBytes);

      print('[OFFLINE_TEST] ✅ Saved to: ${file.path}');
      
      // Show success to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline PDF generated (no cloud formats available)'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (fallbackError) {
      print('[OFFLINE_TEST] ❌ Fallback failed: $fallbackError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate PDF: $fallbackError'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Test 2: Check LocalPdfGenerator Implementation

```dart
// Verify LocalPdfGenerator exists and has required methods
import 'package:aura_sphere_pro/utils/local_pdf_generator.dart';

void testLocalPdfGenerator() async {
  final invoice = InvoiceModel(
    id: 'test-invoice',
    userId: 'test-user',
    invoiceNumber: 'TEST-001',
    clientName: 'Test Client',
    items: [],
    subtotal: 1000,
    tax: 200,
    total: 1200,
    currency: 'USD',
    taxRate: 20,
    status: 'draft',
    createdAt: Timestamp.now(),
  );

  try {
    // Test generation
    final pdfBytes = await LocalPdfGenerator.generateInvoicePdf(
      invoice: invoice,
      businessName: 'My Business',
      businessAddress: '123 Main St',
    );

    print('✅ Local PDF generated: ${pdfBytes.length} bytes');
    
    // Verify it's a valid PDF
    if (pdfBytes.length > 0 && pdfBytes[0] == 0x25 && pdfBytes[1] == 0x50) {
      print('✅ PDF header is valid (%PDF)');
    } else {
      print('❌ PDF header is invalid');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Test 3: Complete Fallback Flow

```dart
class InvoiceExportFallbackTest extends StatefulWidget {
  @override
  State<InvoiceExportFallbackTest> createState() => _InvoiceExportFallbackTestState();
}

class _InvoiceExportFallbackTestState extends State<InvoiceExportFallbackTest> {
  String _status = 'Ready to test';
  String? _error;
  String? _successPath;

  Future<void> testFallback() async {
    setState(() {
      _status = 'Testing offline scenario...';
      _error = null;
      _successPath = null;
    });

    try {
      // Get test invoice
      final invoiceDoc = await FirebaseFirestore.instance
        .collection('invoices')
        .doc('test-invoice-001')
        .get();

      final invoice = InvoiceModel.fromDoc(invoiceDoc);

      setState(() => _status = 'Attempting cloud export...');

      // Try cloud export (will fail due to network simulation)
      try {
        await _simulateNetworkFailure();
      } catch (e) {
        setState(() => _status = 'Cloud export failed, using offline fallback...');

        // Use local fallback
        final pdfBytes = await LocalPdfGenerator.generateInvoicePdf(
          invoice: invoice,
          businessName: 'Test Business',
          businessAddress: '123 Test St',
        );

        // Save file
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/fallback-invoice.pdf');
        await file.writeAsBytes(pdfBytes);

        setState(() {
          _status = '✅ Fallback successful!';
          _successPath = file.path;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Fallback failed';
        _error = e.toString();
      });
    }
  }

  Future<void> _simulateNetworkFailure() {
    return Future.delayed(Duration(seconds: 1))
      .then((_) => throw Exception('Simulated network error'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Offline Fallback Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testFallback,
              child: Text('Test Offline Fallback'),
            ),
            SizedBox(height: 20),
            Text(_status, style: TextStyle(fontSize: 16)),
            if (_error != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
              ),
            ],
            if (_successPath != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ Success!', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Saved to: $_successPath'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

✅ **Offline fallback working?** → Continue to performance monitoring

---

## Monitor Performance

### Cloud Function Logs

```bash
# View function logs
firebase functions:log --limit=50

# Filter by function
firebase functions:log exportInvoiceFormats

# Expected output shows:
# [START] Memory: 120.45MB
# [PDF_DONE] Memory: 420.80MB
# [CSV_DONE] Memory: 425.15MB
# [ZIP_DONE] Memory: 520.32MB
# [COMPLETE] Memory: 485.92MB, Growth: 365.47MB
```

### Detailed Metrics

```bash
# View metrics in Cloud Logging
gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=exportInvoiceFormats" \
  --limit=30 \
  --format=json | jq '.[] | {timestamp: .timestamp, severity: .severity, textPayload: .textPayload}'
```

### Performance Checklist

| Metric | Target | Status | Notes |
|--------|--------|--------|-------|
| **Duration** | < 8 seconds | ⏳ | Time to generate all formats |
| **Memory Usage** | < 1.5GB | ⏳ | Peak during Puppeteer rendering |
| **Success Rate** | > 99% | ⏳ | Should not fail except for bad input |
| **PDF Size** | 200-300KB | ⏳ | Typical invoice PDF |
| **CSV Size** | 40-60KB | ⏳ | Lightweight format |
| **DOCX Size** | 100-150KB | ⏳ | Word document |
| **PNG Size** | 180-250KB | ⏳ | Full page screenshot |
| **ZIP Size** | 400-600KB | ⏳ | All formats bundled |

### Create Monitoring Dashboard

```bash
# List current metrics
gcloud monitoring metrics-descriptors list --filter="metric.type:cloudfunctions*"

# Example: Create custom dashboard
gcloud monitoring dashboards create --config-from-file=monitoring-dashboard.yaml
```

### Monitoring Dashboard Config

```yaml
# monitoring-dashboard.yaml
displayName: "Invoice Export System"
mosaicLayout:
  columns: 12
  tiles:
  - width: 6
    height: 4
    widget:
      title: "Execution Duration"
      xyChart:
        dataSets:
        - timeSeriesQuery:
            timeSeriesFilter:
              filter: 'resource.type="cloud_function" AND resource.labels.function_name="exportInvoiceFormats" AND metric.type="cloudfunctions.googleapis.com/execution_times"'

  - width: 6
    height: 4
    widget:
      title: "Success Rate"
      xyChart:
        dataSets:
        - timeSeriesQuery:
            timeSeriesFilter:
              filter: 'resource.type="cloud_function" AND resource.labels.function_name="exportInvoiceFormats" AND metric.type="cloudfunctions.googleapis.com/execution_count"'

  - width: 6
    height: 4
    widget:
      title: "Memory Usage"
      xyChart:
        dataSets:
        - timeSeriesQuery:
            timeSeriesFilter:
              filter: 'resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/user_memory_utilization"'
```

### Expected Results

✅ **Duration:** 5-8 seconds for all 5 formats
✅ **Memory:** Peak ~1.2GB, average 400MB
✅ **Success:** 100% for valid inputs
✅ **Errors:** 0 (should fail gracefully for invalid inputs)

---

## Security Testing

### Test 1: Authentication Required

```bash
# Try to call function without auth token
curl -X POST \
  https://us-central1-aura-sphere-pro.cloudfunctions.net/exportInvoiceFormats \
  -H "Content-Type: application/json" \
  -d '{"invoiceNumber": "TEST"}'

# Expected error:
# {"error": "UNAUTHENTICATED", "message": "User must be logged in"}
```

### Test 2: Authorization (Invoice Ownership)

```dart
// Try to export invoice owned by different user
Future<void> testAuthorizationCheck() async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('exportInvoiceFormats')
      .call({
        'invoiceId': 'invoice-owned-by-other-user',
        // ... other fields
      });
  } on FirebaseFunctionsException catch (e) {
    print('Expected error: ${e.message}');
    // Expected: "permission-denied" - You do not have permission
  }
}
```

### Test 3: Input Validation

```dart
// Test with invalid data
Future<void> testInputValidation() async {
  final invalidTests = [
    {
      'name': 'Missing invoiceNumber',
      'data': {'invoiceId': 'test', /* no invoiceNumber */},
    },
    {
      'name': 'Invalid email',
      'data': {
        'invoiceNumber': 'TEST',
        'clientEmail': 'not-an-email',
        // ...
      },
    },
    {
      'name': 'Negative amount',
      'data': {
        'invoiceNumber': 'TEST',
        'total': -100, // Invalid
        // ...
      },
    },
  ];

  for (final test in invalidTests) {
    try {
      await FirebaseFunctions.instance
        .httpsCallable('exportInvoiceFormats')
        .call(test['data']);
      print('❌ ${test['name']}: Should have failed');
    } on FirebaseFunctionsException catch (e) {
      print('✅ ${test['name']}: Correctly rejected (${e.code})');
    }
  }
}
```

### Test 4: XSS Prevention (HTML Escaping)

```bash
# Try injection in business name
MALICIOUS='<script>alert("xss")</script>'

curl -X POST \
  https://us-central1-aura-sphere-pro.cloudfunctions.net/exportInvoiceFormats \
  -H "Content-Type: application/json" \
  -d "{
    \"invoiceNumber\": \"TEST\",
    \"businessName\": \"$MALICIOUS\",
    ...
  }"

# Expected: Script is escaped, PDF contains literal text, no execution
```

### Test 5: CSV Injection Prevention

```dart
// Try CSV injection in item name
final data = {
  'items': [{
    'name': '=cmd|"/c calc"!A1', // CSV formula injection
    'quantity': 1,
    'unitPrice': 100,
  }],
  // ... other fields
};

// Download CSV and verify:
// Should contain: =cmd|"/c calc"!A1 (as literal text)
// Should NOT execute formula
```

✅ **All security tests passed?** → Continue to load testing

---

## Load Testing

### Simple Load Test (10 concurrent exports)

```bash
# Using Apache Bench
ab -c 10 -n 10 \
  -H "Authorization: Bearer $TOKEN" \
  -p request-body.json \
  https://us-central1-aura-sphere-pro.cloudfunctions.net/exportInvoiceFormats

# request-body.json contains sample invoice data
```

### Expected Results

```
Concurrency Level:      10
Time taken for tests:   45.234 seconds
Complete requests:      10
Failed requests:        0
Requests per second:    0.22 [#/sec]
Time per request:       4523.4 [ms]
```

### Monitor During Load Test

In separate terminal:

```bash
# Watch logs during test
watch -n 1 'gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=exportInvoiceFormats" --limit=5 --format=json | jq'

# Watch cost in real-time
gcloud billing budgets list
```

### Load Test with Artillery (More Advanced)

```yaml
# load-test.yml
config:
  target: "https://us-central1-aura-sphere-pro.cloudfunctions.net"
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 10
      name: "Ramp up"
    - duration: 60
      arrivalRate: 20
      name: "Sustained"

scenarios:
  - name: "Export All Formats"
    flow:
      - post:
          url: "/exportInvoiceFormats"
          headers:
            Authorization: "Bearer {{ $processEnvironment.TOKEN }}"
          json:
            invoiceNumber: "LOAD-{{ $randomNumber(1, 10000) }}"
            invoiceId: "test-invoice-001"
            # ... other required fields
```

```bash
# Run load test
export TOKEN=$(gcloud auth application-default print-access-token)
artillery run load-test.yml
```

---

## Production Checklist

### Before Going Live

- [ ] ✅ Cloud Function deployed and tested
- [ ] ✅ All 5 export formats working
- [ ] ✅ Storage structure verified
- [ ] ✅ Signed URLs expiring correctly
- [ ] ✅ Flutter app integration tested
- [ ] ✅ Offline fallback working
- [ ] ✅ Error handling tested
- [ ] ✅ Security tests passed
- [ ] ✅ Performance acceptable
- [ ] ✅ Monitoring dashboard created
- [ ] ✅ Audit logging enabled
- [ ] ✅ Cost monitoring set up
- [ ] ✅ Documentation complete
- [ ] ✅ User documentation ready

### After Going Live

- [ ] Monitor error rate (should be < 1%)
- [ ] Monitor performance (should be < 8s average)
- [ ] Monitor costs (should be within budget)
- [ ] Check user feedback
- [ ] Review audit logs weekly
- [ ] Verify storage cleanup is working
- [ ] Update documentation with real-world findings

### Rollback Plan

If issues occur:

```bash
# Option 1: Disable function
gcloud functions delete exportInvoiceFormats --region us-central1

# Option 2: Revert to previous version
gcloud functions deploy exportInvoiceFormats \
  --source functions \
  --entry-point exportInvoiceFormats \
  --runtime nodejs18 \
  --region us-central1 \
  --update-env-vars ENABLE_EXPORT=false
```

---

## Testing Summary

### Test Progress Tracker

| Test | Status | Time | Notes |
|------|--------|------|-------|
| Code compilation | ⏳ | 2 min | `npm run build` |
| Function deployment | ⏳ | 3 min | `firebase deploy --only functions` |
| Sample data creation | ⏳ | 5 min | Create in Firestore Console |
| Cloud Function call | ⏳ | 5 min | Test via Dart/cURL |
| Storage verification | ⏳ | 2 min | List files in console |
| File downloads | ⏳ | 10 min | Test all 5 formats |
| Offline fallback | ⏳ | 10 min | Test local PDF generation |
| Performance check | ⏳ | 5 min | Monitor logs |
| Security tests | ⏳ | 15 min | Auth + validation + injection |
| Load testing | ⏳ | 30 min | 10+ concurrent exports |
| **Total** | | **87 min** | ~1.5 hours for full test suite |

### Quick Test (15 minutes)

For a quick validation before full testing:

1. Deploy function (3 min)
2. Create sample invoice (2 min)
3. Call function from Dart (5 min)
4. Verify storage (2 min)
5. Download one file (3 min)

### Full Test (90 minutes)

Complete validation with all scenarios covered.

---

## Troubleshooting Common Issues

### Issue: "Function not found"

```bash
# Verify deployment
firebase functions:list

# Check region
firebase functions:describe exportInvoiceFormats --region us-central1

# Redeploy if needed
firebase deploy --only functions:exportInvoiceFormats --region us-central1
```

### Issue: "Unauthenticated" Error

```dart
// Ensure user is logged in
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // Show login screen
}

// Check token is fresh
final token = await user?.getIdToken(forceRefresh: true);
```

### Issue: "Permission Denied"

```dart
// Verify invoice ownership
final userId = FirebaseAuth.instance.currentUser!.uid;
final invoiceDoc = await FirebaseFirestore.instance
  .collection('invoices')
  .doc(invoiceId)
  .get();

if (invoiceDoc.data()['userId'] != userId) {
  print('Invoice does not belong to user');
}
```

### Issue: PDF/DOCX Generation Timeout

```typescript
// Check memory usage in logs
if (memoryUsage > 1800) {
  throw new Error('Memory limit exceeded');
}

// Increase timeout or memory:
functions.runWith({
  memory: '4GB', // Increase from 2GB
  timeoutSeconds: 600, // Increase from 300
})
```

### Issue: Storage Files Not Visible

```bash
# Check Firestore rules
firebase firestore:get-metadata --help

# Verify user-scoped path
# Expected: exports/{userId}/{invoiceNumber}/

# Check permissions
gsutil acl get gs://aura-sphere-pro/exports/test-user-001/
```

---

## Next Steps

After all tests pass:

1. ✅ **Deploy to production**
   ```bash
   firebase deploy --only functions:exportInvoiceFormats
   ```

2. ✅ **Enable in Flutter app**
   ```dart
   // Show export button
   showInvoiceExportDialog(context, invoice);
   ```

3. ✅ **Monitor in production**
   - Watch error rate
   - Monitor costs
   - Collect user feedback

4. ✅ **Iterate on feedback**
   - Add requested formats
   - Improve performance
   - Enhance UI/UX

---

**Status:** ✅ READY FOR TESTING  
**Last Updated:** November 27, 2025  
**Estimated Test Time:** 90 minutes  
**Success Criteria:** All tests passing, < 8s duration, < 1% error rate
