# Purchase Order Routes — Navigation Integration

**Date**: December 9, 2025  
**Status**: ✅ **Routes Registered and Ready**

---

## 📍 Route Registration

Two new routes have been added to [lib/config/app_routes.dart](lib/config/app_routes.dart):

### Constants
```dart
static const String poPdfPreview = '/po/pdf';
static const String poEmail = '/po/email';
```

### Imports
```dart
import '../screens/purchase_orders/po_pdf_preview_screen.dart';
import '../screens/purchase_orders/po_email_modal.dart';
```

---

## 🚀 Usage Examples

### 1. Navigate to PO PDF Preview
```dart
// Navigate with PO ID as String argument
Navigator.pushNamed(
  context,
  AppRoutes.poPdfPreview,
  arguments: 'po-12345',  // poId
);
```

**Expected Behavior:**
- POPDFPreviewScreen opens
- Fetches PDF from Cloud Function
- Displays preview with download/share/print options

---

### 2. Navigate to PO Email Modal
```dart
// Navigate with Map arguments
Navigator.pushNamed(
  context,
  AppRoutes.poEmail,
  arguments: {
    'poId': 'po-12345',
    'defaultTo': 'supplier@example.com',  // optional
  },
);
```

**Expected Behavior:**
- POEmailModal opens as bottom sheet
- Pre-fills "To" field if defaultTo provided
- Shows email form with CC/BCC support
- Sends email via Cloud Function on submit

---

## 📋 Route Handler Details

### PO PDF Preview Route
```dart
case poPdfPreview:
  final poId = settings.arguments as String?;
  if (poId == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Missing poId')),
      ),
    );
  }
  return MaterialPageRoute(
    builder: (_) => POPDFPreviewScreen(poId: poId),
    settings: settings,
  );
```

**Parameters:**
- `arguments`: String (poId)

**Error Handling:**
- Shows error if poId is missing
- Fallback to error scaffold

---

### PO Email Route
```dart
case poEmail:
  final args = settings.arguments as Map<String, dynamic>?;
  final poId = args?['poId'] as String?;
  final defaultTo = args?['defaultTo'] as String?;
  if (poId == null) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Missing poId')),
      ),
    );
  }
  return MaterialPageRoute(
    builder: (_) => POEmailModal(
      poId: poId,
      defaultTo: defaultTo,
    ),
    settings: settings,
  );
```

**Parameters:**
- `arguments`: Map<String, dynamic>
  - `poId` (required): String
  - `defaultTo` (optional): String

**Error Handling:**
- Shows error if poId is missing
- defaultTo is optional (can be null)

---

## 💡 Integration Patterns

### From PO List Screen
```dart
// Navigate to PDF preview
onPDFTap: (poId) {
  Navigator.pushNamed(context, AppRoutes.poPdfPreview, arguments: poId);
},

// Navigate to email modal
onEmailTap: (poId, supplierEmail) {
  Navigator.pushNamed(
    context,
    AppRoutes.poEmail,
    arguments: {'poId': poId, 'defaultTo': supplierEmail},
  );
},
```

### From Supplier Detail Screen
```dart
// View PO PDF with supplier email pre-filled
Navigator.pushNamed(
  context,
  AppRoutes.poEmail,
  arguments: {
    'poId': purchaseOrder.id,
    'defaultTo': supplier.email,
  },
);
```

### From Finance Dashboard
```dart
// View PO PDF for reporting
Navigator.pushNamed(
  context,
  AppRoutes.poPdfPreview,
  arguments: po.id,
);
```

---

## ✅ Verification Checklist

- [x] Route constants defined in AppRoutes
- [x] Imports added for both screens
- [x] Route handlers registered in onGenerateRoute()
- [x] Error handling for missing arguments
- [x] Type-safe argument passing
- [x] Both screens accessible via navigation

---

## 🧪 Testing Routes

### Test PDF Preview Route
1. From any screen, run:
   ```dart
   Navigator.pushNamed(context, AppRoutes.poPdfPreview, arguments: 'po-123');
   ```
2. Verify POPDFPreviewScreen opens
3. Verify PDF loads from Cloud Function

### Test Email Route
1. From any screen, run:
   ```dart
   Navigator.pushNamed(
     context,
     AppRoutes.poEmail,
     arguments: {'poId': 'po-123', 'defaultTo': 'test@example.com'},
   );
   ```
2. Verify POEmailModal opens
3. Verify "To" field is pre-filled
4. Verify email form is functional

### Test Error Handling
1. Navigate without arguments:
   ```dart
   Navigator.pushNamed(context, AppRoutes.poPdfPreview);  // Should show error
   ```
2. Verify error message displays

---

## 📊 Route Status

| Route | Constant | Handler | Status |
|-------|----------|---------|--------|
| `/po/pdf` | `poPdfPreview` | ✅ Registered | Ready |
| `/po/email` | `poEmail` | ✅ Registered | Ready |

---

## 🔗 Related Files

- [app_routes.dart](lib/config/app_routes.dart) — Route definitions
- [po_pdf_preview_screen.dart](lib/screens/purchase_orders/po_pdf_preview_screen.dart) — PDF preview
- [po_email_modal.dart](lib/screens/purchase_orders/po_email_modal.dart) — Email modal

---

**Status**: 🟢 **ROUTES READY FOR USE**

