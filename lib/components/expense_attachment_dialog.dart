import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/expense_model.dart';
import '../providers/expense_provider.dart';

class ExpenseAttachmentDialog extends StatefulWidget {
  final String invoiceId;
  final VoidCallback onExpensesAttached;

  const ExpenseAttachmentDialog({
    super.key,
    required this.invoiceId,
    required this.onExpensesAttached,
  });

  @override
  State<ExpenseAttachmentDialog> createState() =>
      _ExpenseAttachmentDialogState();
}

class _ExpenseAttachmentDialogState extends State<ExpenseAttachmentDialog> {
  final Set<String> _selectedExpenseIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load expenses if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final unlinkedExpenses = provider.getUnlinkedExpenses();
        
        // Filter by search
        final filtered = _searchQuery.isEmpty
            ? unlinkedExpenses
            : unlinkedExpenses
                .where((e) =>
                    e.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (e.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                .toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Attach Expenses to Invoice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by merchant or notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),

                // Expenses list
                if (provider.isLoading)
                  const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No unlinked expenses'
                                : 'No matching expenses',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final expense = filtered[idx];
                        final isSelected = _selectedExpenseIds.contains(expense.id);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedExpenseIds.add(expense.id);
                                } else {
                                  _selectedExpenseIds.remove(expense.id);
                                }
                              });
                            },
                            title: Text(
                              expense.merchant,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (expense.date != null)
                                  Text(
                                    'Date: ${expense.formatDate()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (expense.notes != null && expense.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      expense.notes!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            dense: true,
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Summary
                if (_selectedExpenseIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedExpenseIds.length} expense(s) selected',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Total: ${_calculateTotal(filtered).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectedExpenseIds.isEmpty
                          ? null
                          : () => _attachExpenses(context, provider),
                      child: const Text('Attach Selected'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateTotal(List<ExpenseModel> expenses) {
    final selectedExpenses = expenses
        .where((e) => _selectedExpenseIds.contains(e.id))
        .toList();
    return selectedExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> _attachExpenses(
      BuildContext context, ExpenseProvider provider) async {
    for (final expenseId in _selectedExpenseIds) {
      await provider.attachToInvoice(expenseId, widget.invoiceId);
    }

    if (mounted) {
      widget.onExpensesAttached();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedExpenseIds.length} expense(s) attached'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
