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
  State<ExpenseReviewScreenState> createState() =>
      _ExpenseReviewScreenState();
}

class _ExpenseReviewScreenState extends State<ExpenseReviewScreen> {
  late TextEditingController merchantCtrl;
  late TextEditingController dateCtrl;
  late TextEditingController totalCtrl;
  late TextEditingController vatCtrl;
  late TextEditingController currencyCtrl;
  late TextEditingController categoryCtrl;

  bool loading = false;
  String? errorMessage;
  String userCountry = 'US';

  @override
  void initState() {
    super.initState();

    merchantCtrl = TextEditingController(
      text: widget.ocrData["merchant"] ?? '',
    );
    dateCtrl = TextEditingController(
      text: widget.ocrData["date"] ?? '',
    );
    totalCtrl = TextEditingController(
      text: widget.ocrData["total"]?.toString() ?? '',
    );
    vatCtrl = TextEditingController(
      text: widget.ocrData["vat"]?.toString() ?? '',
    );
    currencyCtrl = TextEditingController(
      text: widget.ocrData["currency"] ?? 'USD',
    );
    categoryCtrl = TextEditingController(
      text: widget.ocrData["category"] ?? 'Other',
    );

    _loadUserCountry();
  }

  Future<void> _loadUserCountry() async {
    // TODO: Load from user profile
    setState(() => userCountry = 'US');
  }

  void _calculateVAT() {
    final total = double.tryParse(totalCtrl.text) ?? 0;
    if (total > 0) {
      final vat = TaxService.calculateTaxFromGross(total, userCountry);
      vatCtrl.text = vat.toStringAsFixed(2);
    }
  }

  Future<void> saveExpense() async {
    // Validation
    if (merchantCtrl.text.isEmpty) {
      setState(() => errorMessage = 'Merchant name is required');
      return;
    }

    if (totalCtrl.text.isEmpty ||
        double.tryParse(totalCtrl.text) == null) {
      setState(() => errorMessage = 'Valid total amount is required');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final expense = ExpenseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchant: merchantCtrl.text.trim(),
        date: dateCtrl.text.trim(),
        total: double.parse(totalCtrl.text),
        vat: double.tryParse(vatCtrl.text) ?? 0,
        currency: currencyCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        imageUrl: widget.imageUrl,
        createdAt: DateTime.now(),
      );

      await ExpenseService().addExpense(expense);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => errorMessage = 'Error saving expense: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget field(String label, TextEditingController ctrl, {VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  void dispose() {
    merchantCtrl.dispose();
    dateCtrl.dispose();
    totalCtrl.dispose();
    vatCtrl.dispose();
    currencyCtrl.dispose();
    categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Expense'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Receipt Preview
            if (widget.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
              ),
            if (widget.imageUrl != null) const SizedBox(height: 20),

            // Error Message
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (errorMessage != null) const SizedBox(height: 16),

            // Form Fields
            field('Merchant', merchantCtrl),
            field('Date', dateCtrl),
            field('Total', totalCtrl, onChanged: _calculateVAT),

            // VAT / Tax Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TaxService.formatTaxDisplay(userCountry),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  field('VAT / Tax', vatCtrl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Amount:'),
                      Text(
                        '${currencyCtrl.text} ${(double.tryParse(totalCtrl.text) ?? 0 - double.tryParse(vatCtrl.text) ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            field('Currency', currencyCtrl),
            field('Category', categoryCtrl),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
