# ⚡ Cloud Function Quick Reference - generateInvoicePdf

**Status:** ✅ Production Ready | **Security:** 🔐 High | **Location:** `functions/src/invoices/generateInvoicePdf.ts`

---

## 📦 What It Does

Generates professional PDF invoices and stores them securely in Firebase Storage with signed download URLs.

---

## 🚀 Quick Usage

### Step 1: Call from Flutter
```dart
import 'package:cloud_functions/cloud_functions.dart';

final HttpsCallable generatePdf = 
  FirebaseFunctions.instance.httpsCallable('generateInvoicePdf');

final result = await generatePdf.call({
  'invoiceId': 'inv-123',
  'invoiceNumber': 'INV-0042',
  'createdAt': DateTime.now().toIso8601String(),
  'dueDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
  'items': [
    {
      'name': 'Services',
      'quantity': 1,
      'unitPrice': 1500.00,
      'vatRate': 0.1,
      'total': 1650.00,
    }
  ],
  'currency': 'USD',
  'subtotal': 1500.00,
  'totalVat': 150.00,
  'total': 1650.00,
  'businessName': 'Your Company',
  'clientName': 'Client Name',
  'clientEmail': 'client@example.com',
});

// Get download URL
final pdfUrl = result.data['url'];
```

### Step 2: Use the PDF
```dart
// Download or view the PDF
launchUrl(pdfUrl);
```

---

## 📋 Required Parameters

| Field | Type | Example |
|-------|------|---------|
| `invoiceId` | string | "inv_abc123" |
| `invoiceNumber` | string | "INV-0042" |
| `createdAt` | string | "2025-11-28T10:00:00Z" |
| `dueDate` | string | "2025-12-28T10:00:00Z" |
| `items` | array | [see below] |
| `currency` | string | "USD" |
| `subtotal` | number | 1500.00 |
| `totalVat` | number | 150.00 |
| `total` | number | 1650.00 |
| `businessName` | string | "Your Company" |
| `clientName` | string | "Client Name" |
| `clientEmail` | string | "client@example.com" |

### Items Format
```dart
{
  'name': 'Service description',
  'quantity': 1,
  'unitPrice': 1500.00,
  'vatRate': 0.1,  // 10%
  'total': 1650.00
}
```

---

## 🎁 Optional Parameters

| Field | Type | Default | Example |
|-------|------|---------|---------|
| `businessAddress` | string | "Address not provided" | "123 Main St" |
| `clientAddress` | string | "Address not provided" | "456 Oak Ave" |
| `userLogoUrl` | string | null | "https://..." |
| `paidDate` | string | null | "2025-12-15T10:00:00Z" |
| `notes` | string | null | "Thank you!" |
| `discount` | number | 0 | 50.00 |
| `linkedExpenseCount` | number | 0 | 3 |

---

## 📤 Response

### Success (200)
```dart
{
  'success': true,
  'url': 'https://storage.googleapis.com/...',
  'filePath': 'invoices/userId/INV-0042_1732834800000.pdf',
  'fileName': 'INV-0042.pdf',
  'size': 45678,
  'message': 'PDF generated successfully'
}
```

### Error
```dart
{
  'code': 'unauthenticated|invalid-argument|internal',
  'message': 'Error description'
}
```

---

## ⚙️ Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| **Memory** | 1 GB | For Puppeteer rendering |
| **Timeout** | 120s | Browser launch & rendering |
| **Region** | us-central1 | Optimal latency |
| **Type** | HTTPS Callable | Secure auth via Firebase |

---

## 🔐 Security

✅ **Authentication Required** - User must be logged in  
✅ **User Isolation** - Files stored in `invoices/{userId}/`  
✅ **Signed URLs** - Expire after 30 days  
✅ **Input Validation** - All fields validated  
✅ **HTML Sanitization** - XSS protection  
✅ **Audit Logging** - All operations logged  

---

## 💡 Common Use Cases

### Use Case 1: Download Button
```dart
ElevatedButton(
  onPressed: () async {
    try {
      final result = await generatePdf.call({...});
      final url = result.data['url'];
      await launchUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: Text('Download PDF'),
)
```

### Use Case 2: Save URL to Firestore
```dart
final result = await generatePdf.call({...});
await FirebaseFirestore.instance
    .collection('invoices')
    .doc(invoiceId)
    .update({
      'pdfUrl': result.data['url'],
      'pdfGeneratedAt': FieldValue.serverTimestamp(),
    });
```

### Use Case 3: Email Attachment
```dart
final result = await generatePdf.call({...});
// Use pdfUrl with email service to attach
await sendEmailWithAttachment(
  to: clientEmail,
  pdfUrl: result.data['url'],
);
```

---

## 🐛 Error Handling

```dart
try {
  final result = await generatePdf.call(data);
  print('PDF URL: ${result.data['url']}');
} on FirebaseFunctionsException catch (e) {
  if (e.code == 'unauthenticated') {
    print('Please log in first');
  } else if (e.code == 'invalid-argument') {
    print('Missing or invalid data');
  } else {
    print('Generation failed: ${e.message}');
  }
}
```

---

## 📊 Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Cold start | 3-5s | Puppeteer launch |
| Rendering | 2-3s | HTML to PDF |
| Upload | <1s | Firebase Storage |
| **Total** | 5-10s | End-to-end |

---

## 📍 Location & Exports

**File:** `functions/src/invoices/generateInvoicePdf.ts`  
**Exported in:** `functions/src/index.ts`

```typescript
export { generateInvoicePdf } from './invoices/generateInvoicePdf';
```

---

## 🔧 Firebase Rules

### Storage Rules Required
```firestore
match /invoices/{userId}/{allPaths=**} {
  allow read, write: if request.auth.uid == userId;
}
```

### Firestore Rules Required
```firestore
match /invoices/{invoiceId} {
  allow update: if request.auth.uid == resource.data.userId;
}
```

---

## 📚 Full Documentation

See: [CLOUD_FUNCTION_INVOICE_PDF_GUIDE.md](CLOUD_FUNCTION_INVOICE_PDF_GUIDE.md)

---

## ✨ Features at a Glance

- ✅ Professional PDF layout (A4)
- ✅ Company logo support
- ✅ Multi-currency support
- ✅ VAT/tax calculations
- ✅ Linked expenses tracking
- ✅ Notes & payment terms
- ✅ Print-ready formatting
- ✅ Secure storage
- ✅ 30-day signed URLs
- ✅ Full audit logging

---

**Status:** ✅ Production Ready  
**Security:** 🔐 High  
**Lines:** 596
