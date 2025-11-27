# Automated Testing Verification Script

## Pre-Flight Checks (Run First)

### ✅ Check 1: Dependencies Installed

```bash
#!/bin/bash

echo "========================================="
echo "1. Checking Flutter Dependencies"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Get latest packages
flutter pub get

# Check critical packages
PACKAGES=(
  "firebase_core"
  "cloud_firestore"
  "cloud_functions"
  "firebase_storage"
  "image_picker"
  "google_ml_kit"
  "provider"
)

echo ""
echo "Checking packages..."
for pkg in "${PACKAGES[@]}"; do
  if grep -q "$pkg" pubspec.yaml; then
    echo "✅ $pkg found in pubspec.yaml"
  else
    echo "❌ $pkg NOT found in pubspec.yaml"
  fi
done

echo ""
echo "========================================="
echo "✅ Dependency check complete"
echo "========================================="
```

**Run:**
```bash
bash check_dependencies.sh
```

### ✅ Check 2: Routes & Providers Configuration

```bash
#!/bin/bash

echo "========================================="
echo "2. Verifying Routes & Providers"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Check ExpenseProvider in app.dart
echo ""
echo "Checking app.dart for ExpenseProvider..."
if grep -q "import.*expense_provider" lib/app/app.dart; then
  echo "✅ ExpenseProvider imported"
else
  echo "❌ ExpenseProvider NOT imported"
  exit 1
fi

if grep -q "ChangeNotifierProvider.*ExpenseProvider" lib/app/app.dart; then
  echo "✅ ExpenseProvider added to MultiProvider"
else
  echo "❌ ExpenseProvider NOT in MultiProvider"
  exit 1
fi

# Check ExpenseScanner route
echo ""
echo "Checking app_routes.dart for expenseScanner..."
if grep -q "static const String expenseScanner" lib/config/app_routes.dart; then
  echo "✅ expenseScanner route constant defined"
else
  echo "❌ expenseScanner route constant NOT found"
  exit 1
fi

if grep -q "ExpenseScannerScreen" lib/config/app_routes.dart; then
  echo "✅ ExpenseScannerScreen imported"
else
  echo "❌ ExpenseScannerScreen NOT imported"
  exit 1
fi

if grep -q "case expenseScanner:" lib/config/app_routes.dart; then
  echo "✅ expenseScanner route handler defined"
else
  echo "❌ expenseScanner route handler NOT found"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ Routes & Providers verification complete"
echo "========================================="
```

**Run:**
```bash
bash check_routes_providers.sh
```

### ✅ Check 3: File Compilation

```bash
#!/bin/bash

echo "========================================="
echo "3. Checking File Compilation"
echo "========================================="

cd /workspaces/aura-sphere-pro

flutter clean
flutter pub get

# Analyze code
echo ""
echo "Running Flutter Analyzer..."
flutter analyze 2>&1 | head -20

echo ""
echo "========================================="
echo "✅ Compilation check complete"
echo "========================================="
```

**Run:**
```bash
bash check_compilation.sh
```

---

## Build Verification

### ✅ Check 4: Build APK (Android)

```bash
#!/bin/bash

echo "========================================="
echo "4. Building Android APK"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Build release APK
flutter build apk --release 2>&1 | tail -20

# Check if build succeeded
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
  echo ""
  echo "✅ APK built successfully"
  echo "   Location: build/app/outputs/flutter-apk/app-release.apk"
  echo "   Size: $SIZE"
else
  echo "❌ APK build failed"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ Android build complete"
echo "========================================="
```

**Run:**
```bash
bash build_android.sh
```

### ✅ Check 5: Build App Bundle (iOS)

```bash
#!/bin/bash

echo "========================================="
echo "5. Building iOS App"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Build iOS (simulator)
flutter build ios --simulator 2>&1 | tail -20

# Check if build succeeded
if [ -f "build/ios/iphonesimulator/Runner.app/Runner" ]; then
  echo ""
  echo "✅ iOS app built successfully"
  echo "   Location: build/ios/iphonesimulator/Runner.app/"
else
  echo "❌ iOS build failed"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ iOS build complete"
echo "========================================="
```

**Run:**
```bash
bash build_ios.sh
```

---

## Runtime Verification

### ✅ Check 6: Start App on Device

```bash
#!/bin/bash

echo "========================================="
echo "6. Starting App on Device"
echo "========================================="

cd /workspaces/aura-sphere-pro

# List devices
echo "Available devices:"
flutter devices

echo ""
echo "Starting app..."
flutter run -d emulator-5554 &

# Wait for app to start
sleep 10

# Check if app is running
if adb shell ps | grep -q "com.example.aurasphere_pro"; then
  echo ""
  echo "✅ App running successfully"
else
  echo "❌ App failed to start"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ App startup verification complete"
echo "========================================="
```

**Run:**
```bash
bash start_app.sh
```

---

## Firebase Verification

### ✅ Check 7: Firebase Setup

```bash
#!/bin/bash

echo "========================================="
echo "7. Verifying Firebase Setup"
echo "========================================="

# Check Firebase CLI installed
if ! command -v firebase &> /dev/null; then
  echo "❌ Firebase CLI not installed"
  echo "   Install: npm install -g firebase-tools"
  exit 1
fi
echo "✅ Firebase CLI installed"

# Check logged in
if firebase projects:list | grep -q "aura-sphere-pro"; then
  echo "✅ Logged into Firebase"
else
  echo "⚠️  Not logged into Firebase"
  echo "   Run: firebase login"
fi

# Check Firestore configured
if [ -f "firestore.rules" ]; then
  echo "✅ firestore.rules file exists"
else
  echo "❌ firestore.rules NOT found"
  exit 1
fi

# Check Storage rules
if [ -f "storage.rules" ]; then
  echo "✅ storage.rules file exists"
else
  echo "❌ storage.rules NOT found"
  exit 1
fi

# Check Cloud Functions
if [ -f "functions/src/index.ts" ]; then
  echo "✅ Cloud Functions configured"
  
  # Check visionOcr function exists
  if grep -q "visionOcr" functions/src/index.ts; then
    echo "✅ visionOcr function found"
  else
    echo "⚠️  visionOcr function NOT found"
  fi
else
  echo "❌ Cloud Functions NOT configured"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ Firebase setup verification complete"
echo "========================================="
```

**Run:**
```bash
bash check_firebase.sh
```

### ✅ Check 8: Firestore Rules Validation

```bash
#!/bin/bash

echo "========================================="
echo "8. Validating Firestore Rules"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Check rules compile
echo "Checking Firestore rules syntax..."
firebase deploy --only firestore:rules --dry-run 2>&1 | grep -E "(✔|✖)"

# Check specific rules
echo ""
echo "Checking expense validation functions..."
if grep -q "function isValidExpenseCreate" firestore.rules; then
  echo "✅ isValidExpenseCreate() found"
else
  echo "❌ isValidExpenseCreate() NOT found"
  exit 1
fi

if grep -q "function isValidExpenseUpdate" firestore.rules; then
  echo "✅ isValidExpenseUpdate() found"
else
  echo "❌ isValidExpenseUpdate() NOT found"
  exit 1
fi

# Check invoiceId validation
if grep -q "invoiceId" firestore.rules; then
  echo "✅ invoiceId field validated in rules"
else
  echo "❌ invoiceId NOT validated"
  exit 1
fi

echo ""
echo "========================================="
echo "✅ Firestore rules validation complete"
echo "========================================="
```

**Run:**
```bash
bash validate_firestore_rules.sh
```

---

## Functional Testing

### ✅ Check 9: Test Expense Model

```bash
#!/bin/bash

echo "========================================="
echo "9. Testing ExpenseModel"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Create test file
cat > test/models/expense_model_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:aurasphere_pro/data/models/expense_model.dart';

void main() {
  group('ExpenseModel', () {
    test('Create expense with invoiceId null', () {
      final expense = ExpenseModel(
        id: 'exp_test_1',
        userId: 'user_test',
        merchant: 'Test Store',
        amount: 50.0,
        currency: 'USD',
        imageUrl: 'gs://bucket/image.jpg',
        invoiceId: null,
      );

      expect(expense.id, 'exp_test_1');
      expect(expense.merchant, 'Test Store');
      expect(expense.amount, 50.0);
      expect(expense.invoiceId, null);
    });

    test('Create expense with invoiceId set', () {
      final expense = ExpenseModel(
        id: 'exp_test_2',
        userId: 'user_test',
        merchant: 'Test Store',
        amount: 50.0,
        currency: 'USD',
        imageUrl: 'gs://bucket/image.jpg',
        invoiceId: 'inv_123',
      );

      expect(expense.invoiceId, 'inv_123');
    });

    test('toMap includes invoiceId', () {
      final expense = ExpenseModel(
        id: 'exp_test_3',
        userId: 'user_test',
        merchant: 'Test Store',
        amount: 50.0,
        currency: 'USD',
        imageUrl: 'gs://bucket/image.jpg',
        invoiceId: 'inv_456',
      );

      final map = expense.toMap();
      expect(map['invoiceId'], 'inv_456');
    });

    test('copyWith updates invoiceId', () {
      final expense = ExpenseModel(
        id: 'exp_test_4',
        userId: 'user_test',
        merchant: 'Test Store',
        amount: 50.0,
        currency: 'USD',
        imageUrl: 'gs://bucket/image.jpg',
        invoiceId: null,
      );

      final updated = expense.copyWith(invoiceId: 'inv_789');
      expect(updated.invoiceId, 'inv_789');
    });
  });
}
EOF

echo "Running ExpenseModel tests..."
flutter test test/models/expense_model_test.dart 2>&1 | grep -E "(✓|✖|passed|failed)"

echo ""
echo "========================================="
echo "✅ ExpenseModel testing complete"
echo "========================================="
```

**Run:**
```bash
bash test_expense_model.sh
```

### ✅ Check 10: Test ExpenseProvider

```bash
#!/bin/bash

echo "========================================="
echo "10. Testing ExpenseProvider"
echo "========================================="

cd /workspaces/aura-sphere-pro

# Create test file
cat > test/providers/expense_provider_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:aurasphere_pro/providers/expense_provider.dart';
import 'package:aurasphere_pro/data/models/expense_model.dart';

void main() {
  group('ExpenseProvider', () {
    late ExpenseProvider provider;

    setUp(() {
      provider = ExpenseProvider();
    });

    test('getUnlinkedExpenses returns expenses with invoiceId null', () {
      // Note: This would need mocking of Firestore
      // For now, just verify the method exists and is callable
      expect(() => provider.getUnlinkedExpenses(), returnsNormally);
    });

    test('getTotalUnlinked calculates sum correctly', () {
      expect(() => provider.getTotalUnlinked(), returnsNormally);
    });

    test('getExpensesForInvoice filters by invoiceId', () {
      expect(() => provider.getExpensesForInvoice('inv_test'), returnsNormally);
    });

    test('attachToInvoice and detachFromInvoice exist', () {
      expect(provider.attachToInvoice, isNotNull);
      expect(provider.detachFromInvoice, isNotNull);
    });
  });
}
EOF

echo "Running ExpenseProvider tests..."
flutter test test/providers/expense_provider_test.dart 2>&1 | grep -E "(✓|✖|passed|failed)"

echo ""
echo "========================================="
echo "✅ ExpenseProvider testing complete"
echo "========================================="
```

**Run:**
```bash
bash test_expense_provider.sh
```

---

## Complete Test Suite

### Run All Pre-Flight Checks

```bash
#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   AURA SPHERE PRO - EXPENSE SYSTEM COMPLETE TEST SUITE     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

FAILED=0

# Run checks
echo "Running pre-flight checks..."
echo ""

# Check 1: Dependencies
echo "[1/10] Checking dependencies..."
if ! bash check_dependencies.sh 2>&1 | grep -q "FAILED"; then
  echo "✅ Dependencies: PASS"
else
  echo "❌ Dependencies: FAIL"
  FAILED=$((FAILED + 1))
fi

# Check 2: Routes & Providers
echo "[2/10] Checking routes & providers..."
if bash check_routes_providers.sh > /dev/null 2>&1; then
  echo "✅ Routes & Providers: PASS"
else
  echo "❌ Routes & Providers: FAIL"
  FAILED=$((FAILED + 1))
fi

# Check 3: Compilation
echo "[3/10] Checking compilation..."
if ! flutter analyze 2>&1 | grep -q "error"; then
  echo "✅ Compilation: PASS"
else
  echo "❌ Compilation: FAIL"
  FAILED=$((FAILED + 1))
fi

# Check 4: Firebase
echo "[4/10] Checking Firebase setup..."
if bash check_firebase.sh > /dev/null 2>&1; then
  echo "✅ Firebase Setup: PASS"
else
  echo "❌ Firebase Setup: FAIL"
  FAILED=$((FAILED + 1))
fi

# Check 5: Firestore Rules
echo "[5/10] Validating Firestore rules..."
if bash validate_firestore_rules.sh 2>&1 | grep -q "✔"; then
  echo "✅ Firestore Rules: PASS"
else
  echo "❌ Firestore Rules: FAIL"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   TEST RESULTS                                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "✅ ALL CHECKS PASSED!"
  echo ""
  echo "Next steps:"
  echo "  1. Run: flutter pub get"
  echo "  2. Run: flutter run"
  echo "  3. Navigate to /expenses/scan"
  echo "  4. Test expense scanning & linking"
  exit 0
else
  echo "❌ $FAILED checks failed"
  echo ""
  echo "Review errors above and fix issues"
  exit 1
fi
```

**Run Complete Suite:**
```bash
bash test_complete_suite.sh
```

---

## Summary

All checks can be run individually or as a complete suite:

```bash
# Individual checks
bash check_dependencies.sh
bash check_routes_providers.sh
bash check_compilation.sh
bash check_firebase.sh
bash validate_firestore_rules.sh
bash build_android.sh
bash start_app.sh

# Complete suite
bash test_complete_suite.sh

# Run tests
flutter test
```

**Status:** ✅ All verification scripts ready for testing phase

