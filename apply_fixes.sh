#!/bin/bash

################################################################################
# AuraSphere Pro - Automated Error Fixes
# Applies all safe, automatic fixes to critical errors
# Date: November 28, 2025
################################################################################

set -e

PROJECT_ROOT="/workspaces/aura-sphere-pro"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     AuraSphere Pro - Automated Error Fix Script (v2.0)         ║"
echo "║             Fixing Critical Compilation Errors                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Counter for fixes
TOTAL_FIXES=0
SUCCESSFUL_FIXES=0

# Function to apply fix
apply_fix() {
    local description="$1"
    local file="$2"
    local old_pattern="$3"
    local new_pattern="$4"
    
    echo "→ $description"
    
    if [ ! -f "$file" ]; then
        echo "  ❌ File not found: $file"
        return 1
    fi
    
    if grep -q "$old_pattern" "$file"; then
        sed -i "s/$old_pattern/$new_pattern/g" "$file"
        echo "  ✅ Fixed"
        SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
        return 0
    else
        echo "  ⚠️  Pattern not found (may already be fixed)"
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 APPLYING FIXES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fix 1: expense_review_screen.dart - State type reference
echo "1️⃣  Expense Review Screen Fixes"
apply_fix \
    "Fix ExpenseReviewScreen state type" \
    "lib/screens/expenses/expense_review_screen.dart" \
    "State<ExpenseReviewScreenState> createState" \
    "State<_ExpenseReviewScreenState> createState"

TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Fix 2: expense_scanner_screen.dart - Remove invalid import
echo ""
echo "2️⃣  Expense Scanner Screen Fixes"
echo "→ Remove invalid FirebaseService import"
if grep -q "import '../../services/firebase_service.dart'" \
    "lib/screens/expenses/expense_scanner_screen.dart"; then
    sed -i "/import '..\/..\/services\/firebase_service\.dart'/d" \
        "lib/screens/expenses/expense_scanner_screen.dart"
    echo "  ✅ Removed"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Add Firebase Storage import
echo "→ Add Firebase Storage import"
if ! grep -q "import 'package:firebase_storage/firebase_storage.dart'" \
    "lib/screens/expenses/expense_scanner_screen.dart"; then
    # Insert after cloud_functions import
    sed -i "/import 'package:cloud_functions\/cloud_functions.dart';/a import 'package:firebase_storage/firebase_storage.dart';" \
        "lib/screens/expenses/expense_scanner_screen.dart"
    echo "  ✅ Added"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Fix 3: expense_scanner_screen.dart - Parameter names
echo "→ Fix ExpenseReviewScreen parameter names"
if grep -q "parsedData: _parsedData!" \
    "lib/screens/expenses/expense_scanner_screen.dart"; then
    sed -i "s/parsedData: _parsedData!/ocrData: _parsedData!/g" \
        "lib/screens/expenses/expense_scanner_screen.dart"
    echo "  ✅ Fixed"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Fix 4: waitlist_screen.dart - Remove invalid import
echo ""
echo "3️⃣  Waitlist Screen Fixes"
echo "→ Remove invalid FirestoreService import"
if grep -q "import '../services/firebase/firestore_service.dart'" \
    "lib/screens/waitlist_screen.dart"; then
    sed -i "/import '\.\.\/services\/firebase\/firestore_service\.dart'/d" \
        "lib/screens/waitlist_screen.dart"
    echo "  ✅ Removed"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Add Cloud Firestore import if needed
echo "→ Add Cloud Firestore import if missing"
if ! grep -q "import 'package:cloud_firestore/cloud_firestore.dart'" \
    "lib/screens/waitlist_screen.dart"; then
    sed -i "/import 'package:flutter\/material.dart';/a import 'package:cloud_firestore/cloud_firestore.dart';" \
        "lib/screens/waitlist_screen.dart"
    echo "  ✅ Added"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Fix 5: email_ai_service_examples.dart - Remove invalid imports
echo ""
echo "4️⃣  Email AI Service Examples Fixes"
echo "→ Remove invalid imports"
if grep -q "import '../providers/email_ai_provider.dart'" \
    "lib/services/ai/email_ai_service_examples.dart"; then
    sed -i "/import '\.\.\/providers\/email_ai_provider\.dart'/d" \
        "lib/services/ai/email_ai_service_examples.dart"
    echo "  ✅ Removed email_ai_provider import"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

if grep -q "import '../services/ai/email_ai_service.dart'" \
    "lib/services/ai/email_ai_service_examples.dart"; then
    sed -i "/import '\.\.\/services\/ai\/email_ai_service\.dart'/d" \
        "lib/services/ai/email_ai_service_examples.dart"
    echo "  ✅ Removed email_ai_service import"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

# Fix 6: CRM list screen - State declaration
echo ""
echo "5️⃣  CRM Module Fixes"
echo "→ Verify CRM list screen state declaration"
if grep -q "State<_CrmListScreenState> createState" \
    "lib/screens/crm/crm_list_screen.dart"; then
    echo "  ✅ Already correct"
    SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
else
    if grep -q "_CrmListScreenState createState" \
        "lib/screens/crm/crm_list_screen.dart"; then
        sed -i "s/State<.*> createState/_CrmListScreenState createState/g" \
            "lib/screens/crm/crm_list_screen.dart"
        echo "  ✅ Fixed"
        SUCCESSFUL_FIXES=$((SUCCESSFUL_FIXES + 1))
    fi
fi
TOTAL_FIXES=$((TOTAL_FIXES + 1))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total fixes applied: $SUCCESSFUL_FIXES / $TOTAL_FIXES"
echo ""

# Run analysis
echo "🔍 Running flutter analyze..."
echo ""

ERRORS=$(flutter analyze 2>&1 | grep "error •" | wc -l)

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ NO CRITICAL ERRORS REMAINING!"
    echo ""
    echo "The app is now ready for testing."
else
    echo "⚠️  Remaining errors: $ERRORS"
    echo ""
    echo "Top errors:"
    flutter analyze 2>&1 | grep "error •" | head -5
    echo ""
    echo "See ERROR_FIX_GUIDE.md for manual fixes"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Run dependencies:"
echo "   $ flutter pub get"
echo ""
echo "2. Test the app:"
echo "   $ flutter run"
echo ""
echo "3. Choose device: [1] Linux or [2] Chrome"
echo ""
echo "4. Navigate to CRM: /crm"
echo ""

echo "═══════════════════════════════════════════════════════════════════"
echo "✅ Fix script completed successfully!"
echo "═══════════════════════════════════════════════════════════════════"
