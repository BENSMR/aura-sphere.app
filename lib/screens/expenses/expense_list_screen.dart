import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/expenses/expense_service.dart';
import 'expense_review_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _svc = ExpenseService();
  ExpenseStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
        actions: [
          PopupMenuButton<ExpenseStatus?>(
            onSelected: (status) {
              setState(() => _filterStatus = status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: ExpenseStatus.draft,
                child: Text('Draft'),
              ),
              const PopupMenuItem(
                value: ExpenseStatus.pending_approval,
                child: Text('Pending Approval'),
              ),
              const PopupMenuItem(
                value: ExpenseStatus.approved,
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: ExpenseStatus.rejected,
                child: Text('Rejected'),
              ),
              const PopupMenuItem(
                value: ExpenseStatus.reimbursed,
                child: Text('Reimbursed'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 4),
                  Text(_filterStatus?.toString().split('.').last ?? 'All'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _svc.watchExpenses(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snap.data ?? [];

          // Apply filter
          if (_filterStatus != null) {
            items = items.where((e) => e.status == _filterStatus).toList();
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus != null
                        ? 'No ${_filterStatus?.toString().split('.').last} expenses'
                        : 'No expenses yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final expense = items[i];
              return _ExpenseCard(
                expense: expense,
                service: _svc,
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            mini: true,
            onPressed: () {
              // TODO: open expense scanner
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner coming soon')),
              );
            },
            tooltip: 'Scan Receipt',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'import',
            mini: true,
            onPressed: () {
              // TODO: open CSV import
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV import coming soon')),
              );
            },
            tooltip: 'Import CSV',
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              // TODO: open manual expense form
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manual entry coming soon')),
              );
            },
            tooltip: 'New Expense',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final ExpenseService service;

  const _ExpenseCard({
    required this.expense,
    required this.service,
  });

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Colors.grey;
      case ExpenseStatus.pending_approval:
        return Colors.orange;
      case ExpenseStatus.approved:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.reimbursed:
        return Colors.blue;
    }
  }

  String _getStatusLabel(ExpenseStatus status) {
    return status.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _showActionMenu(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View / Edit
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('View / Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseReviewScreen(
                      ocrData: expense.rawOcr ?? {},
                      imageUrl: expense.photoUrls.isNotEmpty
                          ? expense.photoUrls.first
                          : null,
                    ),
                  ),
                );
              },
            ),

            // Approve (if pending)
            if (expense.status == ExpenseStatus.pending_approval)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Approve'),
                onTap: () async {
                  Navigator.pop(context);
                  await service.changeStatus(
                    expense.id,
                    ExpenseStatus.approved,
                    approverId: service.uid,
                    note: 'Approved via app',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense approved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),

            // Reject (if pending)
            if (expense.status == ExpenseStatus.pending_approval)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Reject'),
                onTap: () async {
                  Navigator.pop(context);
                  await service.changeStatus(
                    expense.id,
                    ExpenseStatus.rejected,
                    approverId: service.uid,
                    note: 'Rejected by approver',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

            // Link to Invoice
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Link to Invoice'),
              onTap: () {
                Navigator.pop(context);
                // TODO: open invoice picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice linking coming soon')),
                );
              },
            ),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Expense?'),
                    content: const Text(
                      'This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await service.deleteExpense(expense.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(expense.status);
    final statusLabel = _getStatusLabel(expense.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: expense.photoUrls.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  expense.photoUrls.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt),
                    );
                  },
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt),
              ),
        title: Text(
          expense.merchant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  expense.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: statusColor,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showActionMenu(context),
        ),
      ),
    );
  }
}