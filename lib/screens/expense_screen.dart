import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expenses_provider.dart';
import '../utils/expense_validator.dart';
import '../core/utils/context_helpers.dart';

/// Expense tracking screen
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemControllers = <TextEditingController>[];
  String _selectedCategory = 'other';
  final List<String> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ExpenseProvider>().loadExpenses();
      context.read<ExpenseProvider>().loadStats();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _descriptionController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItemField() {
    if (_items.length < 20) {
      final controller = TextEditingController();
      _itemControllers.add(controller);
      setState(() {
        _items.add('');
      });
    }
  }

  void _removeItemField(int index) {
    _itemControllers[index].dispose();
    _itemControllers.removeAt(index);
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitExpense() async {
    // Prepare items list
    final items = _itemControllers.map((c) => c.text.trim()).toList();

    // Validate
    final errors = ExpenseValidator.validateExpense(
      amount: double.tryParse(_amountController.text) ?? 0,
      vendor: _vendorController.text,
      items: items,
      description: _descriptionController.text,
      category: _selectedCategory == 'other' ? null : _selectedCategory,
    );

    if (errors.isNotEmpty) {
      showErrorSnackBar(errors.values.first);
      return;
    }

    // Submit
    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountController.text);

    final result = await provider.addExpense(
      amount: amount,
      vendor: _vendorController.text.trim(),
      items: items,
      category: _selectedCategory == 'other' ? null : _selectedCategory,
      description: _descriptionController.text.trim(),
    );

    if (result != null && context.mounted) {
      showSuccessSnackBar('Expense added successfully');

      // Clear form
      _amountController.clear();
      _vendorController.clear();
      _descriptionController.clear();
      for (final c in _itemControllers) {
        c.dispose();
      }
      _itemControllers.clear();
      setState(() {
        _items.clear();
        _selectedCategory = 'other';
      });
    } else if (context.mounted) {
      final provider = context.read<ExpenseProvider>();
      showErrorSnackBar(provider.error ?? 'Failed to add expense');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats Card
              if (provider.stats.isNotEmpty)
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF00E0FF),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              'Total',
                              '\$${(provider.stats['total'] ?? 0).toStringAsFixed(2)}',
                              Colors.blue,
                            ),
                            _buildStatItem(
                              'Approved',
                              '\$${(provider.stats['approved'] ?? 0).toStringAsFixed(2)}',
                              Colors.green,
                            ),
                            _buildStatItem(
                              'Pending',
                              '${provider.stats['pending'] ?? 0}',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Add Expense Form
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF00E0FF),
                    ),
              ),
              const SizedBox(height: 16),

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Vendor field
              TextField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor',
                  hintText: 'e.g., Office Supplies Co',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: [
                  'Travel',
                  'Meals',
                  'Office Supplies',
                  'Equipment',
                  'Software',
                  'Marketing',
                  'Other',
                ]
                    .map((cat) => DropdownMenuItem(
                          value: cat.toLowerCase().replaceAll(' ', '_'),
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Items
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._itemControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: (value) {
                            _items[index] = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'Item ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeItemField(index),
                      ),
                    ],
                  ),
                );
              }),
              if (_items.length < 20)
                TextButton.icon(
                  onPressed: _addItemField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              const SizedBox(height: 12),

              // Description field
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Any additional notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              ElevatedButton(
                onPressed: provider.isLoading ? null : _submitExpense,
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Add Expense'),
              ),
              const SizedBox(height: 32),

              // Expenses list
              Text(
                'Recent Expenses (${provider.expenseCount})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF00E0FF),
                    ),
              ),
              const SizedBox(height: 12),

              if (provider.isLoading && provider.expenseCount == 0)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00E0FF),
                  ),
                )
              else if (provider.expenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Color(0xFF00E0FF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.expenses.map((expense) {
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(expense.vendor),
                      subtitle: Text('${expense.items.join(', ')}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF00E0FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            expense.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: expense.status == 'approved'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
