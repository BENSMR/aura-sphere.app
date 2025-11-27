# Expense System Setup & Testing Quick Start

## 1️⃣ Prerequisites

Ensure you have:
- ✅ Flutter SDK (3.7+)
- ✅ Android Studio / Xcode
- ✅ Firebase CLI (`firebase-tools`)
- ✅ Google Cloud account (for Vision API, optional)
- ✅ Physical device or emulator with camera

---

## 2️⃣ Installation Steps

### Step 1: Install Dependencies

```bash
cd /workspaces/aura-sphere-pro

# Get all Flutter packages
flutter pub get

# Install iOS pods (if on macOS/iOS)
cd ios && pod install && cd ..

# Verify installation
flutter pub list
```

**Expected Output:**
```
aurasphere_pro depends on:
  cloud_firestore ^5.5.0
  cloud_functions ^5.0.4
  firebase_core ^3.6.0
  image_picker ^0.8.7
  google_ml_kit ^0.7.2
  provider ^6.0.5
  ... (other packages)
```

### Step 2: Verify Configuration Files

**Check Firebase Configuration:**
```bash
# Android
ls -la android/app/google-services.json

# iOS
ls -la ios/Runner/GoogleService-Info.plist

# Web (if testing web)
cat web/index.html | grep firebase
```

**If files missing:**
1. Download from Firebase Console
2. Place in correct directories
3. Rebuild: `flutter clean && flutter pub get`

### Step 3: Verify Providers & Routes ✅

**Providers added to app.dart:**
```bash
grep -n "ExpenseProvider" lib/app/app.dart
```

**Expected Output:**
```
7: import '../providers/expense_provider.dart';
42: ChangeNotifierProvider(create: (_) => ExpenseProvider()),
```

**Routes added to app_routes.dart:**
```bash
grep -n "expenseScanner\|ExpenseScannerScreen" lib/config/app_routes.dart
```

**Expected Output:**
```
9: import '../screens/expenses/expense_scanner_screen.dart';
33: case expenseScanner:
34:   return MaterialPageRoute(builder: (_) => const ExpenseScannerScreen());
```

✅ **Status:** Routes and providers configured correctly

---

## 3️⃣ Run on Device

### Android Device/Emulator

```bash
# List available devices
flutter devices

# Run on Android
flutter run -d <device_id>

# Example:
flutter run -d emulator-5554
```

### iOS Device/Simulator

```bash
# Run on iOS
flutter run -d <device_id>

# Example (iPhone simulator):
flutter run -d "iPhone 14 Pro"
```

### With Verbose Logging

```bash
flutter run -v
```

**Expected Output:**
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (21.5MB).
Installing and launching...
D/flutter (12345): Flutter app is running
I/flutter (12345): ✓ All providers initialized
I/flutter (12345): ✓ Routes configured
```

---

## 4️⃣ First Test: Navigate to Expense Scanner

### In App (via UI)

1. **Launch app** → `flutter run`
2. **Login** with test account
3. **Go to Dashboard**
4. **Tap "Expense Scanner"** (if button exists)

### Via Direct Navigation (Code)

```dart
// Add button to dashboard temporarily for testing
FloatingActionButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.expenseScanner);
  },
  tooltip: 'Test Expense Scanner',
  child: const Icon(Icons.camera_alt),
)
```

### Via Command (Debugging)

```bash
# After app is running, in another terminal:
adb shell am start -n com.example.aurasphere_pro/.MainActivity -a android.intent.action.VIEW
```

**Expected Screen:**
```
┌────────────────────────────┐
│   Expense Scanner          │
├────────────────────────────┤
│                            │
│     [Camera Preview]       │
│                            │
│  [🎥 Camera] [🖼️ Gallery]  │
├────────────────────────────┤
│     [Capture] [Cancel]     │
└────────────────────────────┘
```

---

## 5️⃣ Test Camera Permissions

### Android

App should request:
```
"Allow AuraSphere to access camera?"
[Deny] [Allow]
```

**Grant permission** and verify:
- ✅ Camera preview starts
- ✅ Live feed displays
- ✅ Can switch cameras (front/back)

### iOS

App should request:
```
"'AuraSphere' Would Like to Access the Camera"
[Don't Allow] [Allow]
```

**Grant permission** and verify:
- ✅ Camera feed visible
- ✅ "Allow Once" or "Always Allow" works

---

## 6️⃣ Test Receipt Scanning

### What You Need

- 📸 Real receipt OR test image with text
- 📖 Clear, readable receipt
- ☀️ Good lighting
- 📐 Receipt fills frame

### Test Steps

1. **Open ExpenseScannerScreen**
2. **Position camera over receipt**
   - Fill frame with receipt
   - Ensure text is readable
   - Wait 2 seconds for focus
3. **Tap "Capture"**
4. **Watch for OCR detection**

### Expected Result

```
Scanning receipt...
↓
ML Kit Text Detection: ✓
- Detects text blocks
- Extracts merchant
- Finds amounts
- Identifies dates

Display Fields:
✅ 🏪 Merchant: Acme Corp
✅ 💰 Amount: 49.99
✅ 💱 Currency: USD
✅ 📅 Date: 27.11.2025
✅ 🧾 VAT: 4.99
✅ 📝 Notes: (editable)
```

**Manually Verify Each Value:**

| Field | Receipt Value | Detected | Match? |
|-------|---------------|----------|--------|
| Merchant | ACME CORP | `Acme Corp` | ✅ |
| Amount | $49.99 | `49.99` | ✅ |
| Currency | USD | `USD` | ✅ |
| Date | 27 NOV 2025 | `27.11.2025` | ✅ |
| VAT | $4.99 | `4.99` | ✅ |

---

## 7️⃣ Save Expense to Firestore

### Steps

1. **Review detected data** (from Step 6)
2. **Edit any incorrect fields** (tap to edit)
3. **Tap "Save" button**
4. **Watch for success notification**

### Expected Behavior

```
Saving expense...
└─ Uploading image to Storage...
   └─ Uploading to: receipts/{userId}/{expenseId}
└─ Creating Firestore document...
   └─ Writing to: users/{userId}/expenses/{expenseId}
└─ Validating with Firestore rules...
   └─ Check: required fields ✓
   └─ Check: user ownership ✓
   └─ Check: field count ≤ 16 ✓

✅ Success: Expense saved!
```

**Toast Notification:**
```
✅ Expense saved successfully!
```

### What Happens in Background

**1. Image Upload to Storage**
```
gs://aura-sphere-pro-bucket/receipts/{userId}/{expenseId}
├─ File: image.jpg
├─ Size: ~500KB - 3MB
├─ Format: JPEG/PNG
└─ Access: public (via signed URL)
```

**2. Firestore Document Created**
```
Path: users/{userId}/expenses/{expenseId}

Document Content:
{
  "id": "exp_abc123",
  "userId": "user_xyz789",
  "merchant": "Acme Corp",
  "amount": 49.99,
  "currency": "USD",
  "imageUrl": "gs://bucket/receipts/.../image.jpg",
  "vat": 4.99,
  "date": Timestamp(27.11.2025),
  "category": "Supplies",
  "notes": "",
  "invoiceId": null,
  "isReceipt": true,
  "createdAt": Timestamp(now),
  "updatedAt": Timestamp(now)
}
```

**3. Firestore Rules Applied**
- Validates all required fields
- Checks user ownership (userId == auth.uid)
- Enforces field count limit (≤ 16)
- Validates data types
- Blocks invalid writes

---

## 8️⃣ Verify in Firestore Console

### Navigate to Firestore

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select project: **aura-sphere-pro**
3. Go to **Firestore Database**
4. Click **Data** tab
5. Expand: `users` → `{your_user_id}` → `expenses`

### Expected Structure

```
📁 Firestore
└─ 📁 users
   └─ 📁 user_xyz789 (YOUR USER ID)
      └─ 📁 expenses
         └─ 📄 exp_abc123
            ├─ id: "exp_abc123"
            ├─ userId: "user_xyz789"
            ├─ merchant: "Acme Corp"
            ├─ amount: 49.99
            ├─ currency: "USD"
            ├─ imageUrl: "gs://bucket/..."
            ├─ vat: 4.99
            ├─ date: Timestamp
            ├─ invoiceId: null
            ├─ createdAt: Timestamp
            └─ updatedAt: Timestamp
```

### Verify Each Field

| Field | Expected | Check |
|-------|----------|-------|
| `id` | Matches document ID | ✅ |
| `userId` | Your authenticated ID | ✅ |
| `merchant` | From receipt | ✅ |
| `amount` | Total amount | ✅ |
| `currency` | 3-letter code | ✅ |
| `imageUrl` | gs:// URL | ✅ |
| `vat` | VAT amount | ✅ |
| `invoiceId` | `null` (unlinked) | ✅ |
| `createdAt` | Current timestamp | ✅ |

---

## 9️⃣ Test Invoice Linking

### Step 1: Create Invoice

1. Navigate to invoices section
2. Tap "New Invoice" or "Create Invoice"
3. Fill in details:
   - **Client Name:** Test Client
   - **Invoice Number:** INV-001
   - **Date:** Today
4. Tap "Create"

**Expected:** Invoice INV-001 created in Firestore

### Step 2: Open Invoice Details

1. Find INV-001 in invoice list
2. Tap to open details
3. Look for "Attach Expenses" button

**Expected Button:**
```
[📎 Attach Expenses] [💾 Save] [🗑️ Delete]
```

### Step 3: Open Attachment Dialog

1. Tap "Attach Expenses" button
2. Dialog opens showing all unlinked expenses

**Expected Dialog:**
```
┌─────────────────────────────────────┐
│  Attach Expenses to Invoice         │
├─────────────────────────────────────┤
│ [Search by merchant or notes...]    │
├─────────────────────────────────────┤
│ ☐ Acme Corp              $49.99    │
│   Scanned on 27.11.2025             │
│                                     │
│ ☐ (other expenses...)               │
├─────────────────────────────────────┤
│ 0 selected • Total: $0.00           │
├─────────────────────────────────────┤
│             [Cancel]  [Attach]      │
└─────────────────────────────────────┘
```

### Step 4: Select & Attach

1. **Check 2-3 expenses** by tapping checkboxes
2. Watch "Total" update in real-time
3. Tap "Attach" button

**Expected Updates:**
```
Before selection:
0 selected • Total: $0.00

After checking Acme Corp ($49.99):
1 selected • Total: $49.99

After checking another ($5.50):
2 selected • Total: $55.49

[Tap Attach]
↓
Loading...
↓
✅ 2 expenses attached to invoice!
```

### Step 5: Verify in Firestore

**Attached Expenses:**
```firestore
Document: exp_abc123
├─ invoiceId: "INV-001"  ← CHANGED (was null)
└─ updatedAt: Timestamp(now)

Document: exp_def456
├─ invoiceId: "INV-001"  ← CHANGED (was null)
└─ updatedAt: Timestamp(now)
```

**Unlinked Expenses:**
```firestore
Document: exp_ghi789
├─ invoiceId: null  ← UNCHANGED (still unlinked)
└─ updatedAt: Timestamp(past)
```

---

## 🔟 Verify Provider Methods

### Test in Dart Code

```dart
// In ExpenseScannerScreen or test widget
final provider = context.read<ExpenseProvider>();

// Load all expenses
await provider.loadExpenses();

// Get unlinked
final unlinked = provider.getUnlinkedExpenses();
debugPrint('Unlinked: ${unlinked.length}');

// Get linked
final linked = provider.getExpensesForInvoice('INV-001');
debugPrint('Linked to INV-001: ${linked.length}');

// Get totals
final unlinkedTotal = provider.getTotalUnlinked();
final linkedTotal = provider.getTotalLinked();
debugPrint('Unlinked Total: \$$unlinkedTotal');
debugPrint('Linked Total: \$$linkedTotal');
```

**Expected Console Output:**
```
I/flutter: Unlinked: 3
I/flutter: Linked to INV-001: 2
I/flutter: Unlinked Total: $60.50
I/flutter: Linked Total: $55.49
```

---

## ⚠️ Troubleshooting

### Issue: "ExpenseProvider not found"

**Solution:**
```bash
# Verify import in app.dart
grep "import.*expense_provider" lib/app/app.dart

# Should show:
# import '../providers/expense_provider.dart';

# Verify in MultiProvider list
grep -A 10 "MultiProvider" lib/app/app.dart
# Should include: ChangeNotifierProvider(create: (_) => ExpenseProvider())

# Rebuild
flutter clean && flutter pub get && flutter run
```

### Issue: "Route expenseScanner not found"

**Solution:**
```bash
# Verify route constant
grep "expenseScanner" lib/config/app_routes.dart

# Verify import
grep "ExpenseScannerScreen" lib/config/app_routes.dart

# Verify in onGenerateRoute
grep -A 2 "case expenseScanner" lib/config/app_routes.dart
```

### Issue: "Camera permission denied"

**Solution:**
1. Check Android `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

2. Check iOS `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to scan receipts</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>We need photo library access to select receipts</string>
   ```

3. Grant permissions in device settings:
   - **Android:** Settings → Apps → AuraSphere → Permissions
   - **iOS:** Settings → AuraSphere → Camera/Photos

### Issue: "Firestore write denied"

**Solution:**
1. Check Firestore rules are deployed:
   ```bash
   firebase rules:list
   ```

2. Check rules contain expense collection:
   ```bash
   grep -A 20 "match /expenses" firestore.rules
   ```

3. Verify auth user exists:
   ```bash
   # In Firebase Console → Authentication → Users
   # Your test user should be listed
   ```

4. Check console for validation errors:
   ```bash
   firebase functions:log | grep "isValidExpense"
   ```

### Issue: "Image upload fails"

**Solution:**
1. Check Storage rules are deployed:
   ```bash
   firebase storage:get rules
   ```

2. Check Storage bucket permissions:
   - Firebase Console → Storage → Rules
   - Should allow authenticated users to read/write

3. Check file size:
   - Max 5MB per expense image
   - If larger, compress: `ffmpeg -i input.jpg -q:v 2 output.jpg`

---

## ✅ Quick Checklist

- [ ] `flutter pub get` successful
- [ ] `flutter run` starts app without errors
- [ ] ExpenseProvider registered in app.dart
- [ ] ExpenseScanner route registered in app_routes.dart
- [ ] Can navigate to `/expenses/scan` successfully
- [ ] Camera permission dialog appears
- [ ] Can capture receipt photo
- [ ] OCR detects text and populates fields
- [ ] Save button works without errors
- [ ] Expense appears in Firestore
- [ ] Image accessible via Storage URL
- [ ] Provider methods return correct data
- [ ] Invoice attachment dialog appears
- [ ] Can select and attach expenses
- [ ] invoiceId field updated in Firestore
- [ ] Unlinked count decremented correctly

---

## 📊 Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Dependencies** | ✅ | All packages in pubspec.yaml |
| **Routes** | ✅ | expenseScanner added to app_routes.dart |
| **Providers** | ✅ | ExpenseProvider added to app.dart |
| **Database** | ✅ | Firestore rules deployed with validation |
| **OCR** | ✅ | ML Kit + Cloud Vision optional |
| **Storage** | ✅ | Images stored in gs://bucket/receipts/ |
| **Linking** | ✅ | invoiceId field supports linking |
| **UI** | ✅ | All screens implemented |

---

## Next Steps

1. ✅ Run through setup (this guide)
2. ✅ Run through testing (TESTING_EXPENSE_SYSTEM.md)
3. ✅ Fix any issues found
4. ✅ Deploy to production: `firebase deploy --only functions,firestore:rules,storage:rules`
5. ✅ Monitor usage in Firebase Console

---

## Support Resources

- 📖 [Expenses to Invoices Integration](docs/expenses_to_invoices_integration.md)
- 📖 [Cloud Vision Integration](docs/cloud_vision_integration.md)
- 📖 [Firestore Security Rules](docs/firestore_expenses_security.md)
- 📖 [Vision OCR Function Guide](docs/vision_ocr_function_guide.md)
- 📖 [ExpenseModel Guide](docs/expense_model_guide.md)

**Ready to test? Start with Step 1: Install Dependencies** ✅

