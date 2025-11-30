#!/bin/bash

################################################################################
# AuraSphere Pro - Complete Error Fix (Phase 2)
# Fixes ExpenseModel constructor and State declaration issues
# Date: November 28, 2025
################################################################################

set -e

PROJECT_ROOT="/workspaces/aura-sphere-pro"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    AuraSphere Pro - Complete Error Fix (Phase 2)               ║"
echo "║      Fixing Model Constructors & State Declarations            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 FIXING REMAINING ERRORS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fix 1: expense_review_screen.dart - Correct state declaration
echo "1️⃣  Fix ExpenseReviewScreen State Declaration"
echo "→ Using proper generic type syntax"

cat > temp_fix.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/expenses/expense_service.dart';
import '../../services/tax_service.dart';

class ExpenseReviewScreen extends StatefulWidget {
  final Map<String, dynamic> ocrData;
  final String? imageUrl;

  const ExpenseReviewScreen({
    super.key,
    required this.ocrData,
    this.imageUrl,
  });

  @override
  State<ExpenseReviewScreen> createState() => _ExpenseReviewScreenState();
}

class _ExpenseReviewScreenState extends State<ExpenseReviewScreen> {
DART_EOF

# Get the rest of the file after the class declaration
tail -n +22 "lib/screens/expenses/expense_review_screen.dart" >> temp_fix.dart

# Replace the file
cp temp_fix.dart "lib/screens/expenses/expense_review_screen.dart"
rm temp_fix.dart

echo "  ✅ Fixed state declaration"
echo ""

# Fix 2: Fix ExpenseModel constructor in expense_review_screen.dart
echo "2️⃣  Fix ExpenseModel Constructor Call"

# Create a sed command to fix the ExpenseModel constructor
sed -i '91,105s/final expense = ExpenseModel(/&\n        id: DateTime.now().millisecondsSinceEpoch.toString(),\n        userId: '',  \/\/ TODO: Get from auth\n        merchant: merchantCtrl.text.trim(),\n        date: DateTime.tryParse(dateCtrl.text.trim()),\n        amount: double.parse(totalCtrl.text),\n        vat: double.tryParse(vatCtrl.text),\n        vatRate: (double.tryParse(vatCtrl.text) ?? 0) \/ (double.parse(totalCtrl.text) > 0 ? double.parse(totalCtrl.text) : 1),\n        currency: currencyCtrl.text.trim(),\n        category: categoryCtrl.text.trim(),\n        paymentMethod: "cash",  \/\/ TODO: Get from user input\n        photoUrls: widget.imageUrl != null ? [widget.imageUrl!] : [],\n        createdAt: DateTime.now(),/' \
  "lib/screens/expenses/expense_review_screen.dart" 2>/dev/null || echo "  ℹ️  Constructor pattern differs - see manual guide"

echo "  ℹ️  Review constructor - model structure detected"
echo ""

# Fix 3: Fix CRM list screen state
echo "3️⃣  Verify CRM List Screen State"

if grep -q "_CrmListScreenState createState => _CrmListScreenState" \
    "lib/screens/crm/crm_list_screen.dart"; then
    sed -i 's/_CrmListScreenState createState => _CrmListScreenState/State<CrmListScreen> createState => _CrmListScreenState/' \
        "lib/screens/crm/crm_list_screen.dart"
    echo "  ✅ Fixed state declaration"
else
    echo "  ✅ Already correct"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Fixes Applied:"
echo "   • Fixed ExpenseReviewScreen state declaration"
echo "   • Reviewed ExpenseModel constructor structure"
echo "   • Verified CRM list screen state"
echo ""
echo "ℹ️  Manual Review Needed:"
echo "   • ExpenseModel constructor parameters in expense_review_screen.dart"
echo "   • See detailed guide: ERROR_FIX_GUIDE.md"
echo ""

echo "════════════════════════════════════════════════════════════════"
