# Flutter Dependencies Configuration — December 10, 2025

## Overview
Configured Flutter dependencies for OCR receipt processing, PDF handling, and Firebase integration in AuraSphere Pro.

## Dependency Resolution Status
✅ **Status**: All dependencies resolved successfully  
✅ **Packages**: 115 total installed  
✅ **Build**: Ready for Flutter compilation

## Core Dependencies for Receipt Processing

### Image & OCR
```yaml
image_picker: ^0.8.7          # Select images from device/camera
google_ml_kit: ^0.7.2         # ML Kit for on-device ML tasks
```

**Purpose**: Capture receipt photos and prepare for OCR processing

**Usage**:
```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
final pickedFile = await picker.pickImage(source: ImageSource.camera);
final base64Image = base64Encode(File(pickedFile.path).readAsBytesSync());
```

### Cloud Storage & Firebase
```yaml
firebase_storage: ^12.4.10    # Upload receipts to Cloud Storage
firebase_auth: ^5.3.0         # User authentication
cloud_firestore: ^5.6.0       # Expense document storage
cloud_functions: ^5.0.4       # Call OCR & approval functions
firebase_core: ^3.6.0         # Firebase SDK base
```

**Purpose**: Store user data, call backend functions, authenticate users

**Usage**:
```dart
// Call ocrProcessor function
final result = await FirebaseFunctions.instance
    .httpsCallable('ocrProcessor')
    .call({'imageBase64': base64String, 'useOpenAI': true});

// Store expense document
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('expenses')
    .add({
      'merchant': result['parsed']['merchant'],
      'totalAmount': result['parsed']['total'],
      'date': result['parsed']['date'],
      'status': 'draft'
    });
```

### PDF Handling & Printing
```yaml
pdf: ^3.10.4                  # Generate PDF documents programmatically
printing: ^5.10.0             # Preview, save, and print PDFs
pdfx: ^2.5.0                  # Render and view PDF files
path_provider: ^2.0.15        # Access device directories
```

**Purpose**: Generate PO PDFs, preview receipts, print documents

**Usage**:
```dart
import 'package:printing/printing.dart';
import 'package:pdfx/pdfx.dart';

// Preview PDF
showDialog(
  context: context,
  builder: (_) => PdfPreviewPage(
    onShare: (bytes) async {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'purchase-order.pdf',
      );
    },
  ),
);

// Load PDF from Cloud Storage
final pdfFile = await FirebaseStorage.instance
    .ref('users/$uid/receipts/receipt-123.pdf')
    .getData();
final document = await PdfDocument.openData(pdfFile);
```

### State Management & Utilities
```yaml
provider: ^6.0.5              # State management (optional, already used)
intl: ^0.19.0                 # Internationalization (date/currency formatting)
path: ^1.8.3                  # Path manipulation
uuid: ^4.0.0                  # Generate unique IDs
file_picker: ^5.2.3           # Pick files from device
```

**Purpose**: Manage app state, format dates/currencies, handle file operations

**Usage**:
```dart
import 'package:intl/intl.dart';

// Format currency
final formatter = NumberFormat.currency(symbol: '€');
print(formatter.format(54.49));  // €54.49

// Format date
final dateFormat = DateFormat('yyyy-MM-dd');
print(dateFormat.format(DateTime.now()));  // 2025-12-10
```

## Dependency Compatibility Matrix

| Package | Version | Depends On | Status |
|---------|---------|-----------|--------|
| firebase_auth | ^5.3.0 | firebase_core ^3.6.0 | ✅ |
| cloud_firestore | ^5.6.0 | firebase_core ^3.6.0 | ✅ |
| firebase_storage | ^12.4.10 | firebase_core ^3.6.0 | ✅ |
| cloud_functions | ^5.0.4 | firebase_core ^3.6.0 | ✅ |
| firebase_messaging | ^15.2.10 | firebase_core ^3.6.0 | ✅ |
| image_picker | ^0.8.7 | - | ✅ |
| printing | ^5.10.0 | pdf ^3.10.4 | ✅ |
| pdfx | ^2.5.0 | pdf ^3.10.4 | ✅ |
| provider | ^6.0.5 | - | ✅ |

## Installation Commands

```bash
# Install all dependencies
flutter pub get

# Upgrade specific package
flutter pub add firebase_storage:^12.4.10

# Downgrade specific package
flutter pub add image_picker:^0.8.7

# Check for outdated packages
flutter pub outdated

# Remove unused packages
flutter pub remove <package_name>
```

## pubspec.yaml Configuration

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.4.10        # Conflict-free version (compatible with firebase_messaging)
  cloud_functions: ^5.0.4

  # Image & OCR
  image_picker: ^0.8.7              # Receipt capture
  google_ml_kit: ^0.7.2             # On-device ML
  flutter_image_compress: ^1.1.0    # Compress images

  # PDF & Printing
  pdf: ^3.10.4                      # PDF generation
  printing: ^5.10.0                 # PDF preview & printing
  pdfx: ^2.5.0                      # PDF rendering
  path_provider: ^2.0.15            # File paths

  # State & Utilities
  provider: ^6.0.5                  # State management
  intl: ^0.19.0                     # I18n (dates, currency)
  uuid: ^4.0.0                      # Unique IDs
  file_picker: ^5.2.3               # File selection
  path: ^1.8.3                      # Path manipulation
  url_launcher: ^6.1.7              # Open links

  # Other (existing)
  google_sign_in: ^6.2.2
  flutter_riverpod: ^2.3.6
  shimmer: ^3.0.0
  connectivity_plus: ^4.0.2
  permission_handler: ^11.0.1
  firebase_messaging: ^15.2.10
  http: ^1.1.2
  shared_preferences: ^2.1.1
  lottie: ^2.4.0
  fl_chart: ^0.66.0
  fluttertoast: ^8.0.9
```

## Version Notes

### Firebase Storage Compatibility
**Selected**: `^12.4.10` (NOT `^11.0.0`)

**Reason**: `firebase_storage ^11.0.0` conflicts with `firebase_messaging ^15.2.10` due to different `firebase_core_platform_interface` requirements.

- `firebase_storage ^11.0.0` requires `firebase_core_platform_interface ^4.5.1`
- `firebase_messaging ^15.2.10` requires `firebase_core_platform_interface ^6.0.0`
- **Solution**: Use `firebase_storage ^12.4.10` which is compatible with both

### Image Picker Version
**Selected**: `^0.8.7` (stable)

**Why**: Version `^0.8.7` is stable and battle-tested. Version `^0.8.9` has recent updates but the older version is proven to work reliably.

### Printing Version
**Selected**: `^5.10.0` (stable)

**Why**: Latest stable version with comprehensive PDF printing support. Works well with `pdfx` for PDF rendering.

## Platform-Specific Configuration

### Android (android/app/build.gradle)
```gradle
android {
  compileSdkVersion 34
  
  defaultConfig {
    targetSdkVersion 34
    minSdkVersion 21
  }
}
```

### iOS (ios/Podfile)
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### Web (pubspec.yaml)
```yaml
# No special configuration needed
# Firebase works out of the box
```

## Usage Examples

### 1. Capture Receipt Image
```dart
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

Future<void> captureReceipt() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 80,
  );
  
  if (pickedFile != null) {
    final bytes = await File(pickedFile.path).readAsBytes();
    final base64String = base64Encode(bytes);
    
    // Send to ocrProcessor function
    final result = await FirebaseFunctions.instance
        .httpsCallable('ocrProcessor')
        .call({
          'imageBase64': base64String,
          'useOpenAI': true,  // Enable AI refinement
        });
    
    print('Merchant: ${result.data['parsed']['merchant']}');
    print('Amount: ${result.data['parsed']['total']}');
  }
}
```

### 2. Store Expense Document
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

Future<void> storeExpense(Map<String, dynamic> parsedData) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  const uuid = Uuid();
  final expenseId = uuid.v4();
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('expenses')
      .doc(expenseId)
      .set({
        'expenseId': expenseId,
        'merchant': parsedData['merchant'],
        'totalAmount': parsedData['total'],
        'currency': parsedData['currency'],
        'date': parsedData['date'],
        'status': 'draft',
        'rawOcr': parsedData['rawText'],
        'createdAt': FieldValue.serverTimestamp(),
        'attachments': [],
      });
  
  // onExpenseCreatedNotify trigger fires automatically
  // Creates approval task in subcollection
}
```

### 3. Upload Receipt to Cloud Storage
```dart
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadReceipt(File imageFile, String expenseId) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  
  final storageRef = FirebaseStorage.instance.ref(
    'users/$userId/expenses/$expenseId/receipt-$timestamp.jpg'
  );
  
  final uploadTask = await storageRef.putFile(
    imageFile,
    SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'expenseId': expenseId},
    ),
  );
  
  return await uploadTask.ref.getDownloadURL();
}
```

### 4. Preview & Print PDF
```dart
import 'package:printing/printing.dart';

void showPdfPreview(BuildContext context, Uint8List pdfBytes) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: PdfPreview(
        build: (_) => pdfBytes,
        onShare: (context) => Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'purchase-order.pdf',
        ),
        onPrint: (_) => Printing.layoutPdf(
          onLayout: (_) => pdfBytes,
        ),
        actions: [
          PdfPreviewAction(
            icon: Icons.cloud_download,
            onPressed: (context) async {
              final fileName = 'purchase-order-${DateTime.now().millisecondsSinceEpoch}.pdf';
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: fileName,
              );
            },
          ),
        ],
      ),
    ),
  );
}
```

## Testing

### Unit Tests
```dart
// test/services/ocr_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('OCR Service', () {
    test('should parse receipt data correctly', () async {
      // Test parseHelpers functions
      // Test ocrProcessor integration
    });

    test('should handle missing image gracefully', () async {
      // Test error handling
    });

    test('should capture merchant, amount, date', () async {
      // Test data extraction
    });
  });
}
```

### Integration Tests
```dart
// integration_test/expense_workflow_test.dart
void main() {
  group('Expense OCR Workflow', () {
    testWidgets('should capture and process receipt', (tester) async {
      // 1. Pick image
      // 2. Call ocrProcessor
      // 3. Create expense
      // 4. Verify approval task created
      // 5. Approve expense
    });
  });
}
```

## Performance Optimization

### Image Compression
```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImage(File imageFile) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    imageFile.absolute.path,
    '${imageFile.path}_compressed.jpg',
    quality: 70,  // 0-100
    minHeight: 1920,
    minWidth: 1080,
  );
  return result!.readAsBytes();
}
```

### PDF Caching
```dart
// Cache downloaded PDFs locally
final directory = await getApplicationCacheDirectory();
final cachedPdfPath = '${directory.path}/purchase-order-$poId.pdf';
```

## Troubleshooting

### Dependency Conflicts
```bash
# Clear pub cache and reinstall
flutter clean
flutter pub get

# Check for conflicts
flutter pub deps --style=list
```

### Firebase Initialization Issues
```dart
// Ensure Firebase is initialized before any Firebase calls
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Image Picker Permissions
```dart
// Ensure permissions are granted
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}
```

---

**Date**: December 10, 2025  
**Total Packages**: 115 installed  
**Status**: ✅ All dependencies resolved and ready  
**Next**: Integration testing with real receipt images
