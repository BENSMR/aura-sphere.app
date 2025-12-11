import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    Key? key,
    required this.expenseId,
  }) : super(key: key);

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  Map<String, dynamic>? expense;
  bool loading = true;
  String? error;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          error = 'Not authenticated';
          loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(widget.expenseId)
          .get();

      if (!doc.exists) {
        setState(() {
          error = 'Expense not found';
          loading = false;
        });
        return;
      }

      setState(() {
        expense = doc.data();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading expense: $e';
        loading = false;
      });
    }
  }

  Future<void> _updateExpenseStatus(String newStatus, String action) async {
    try {
      setState(() => isProcessing = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(widget.expenseId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'audit': FieldValue.arrayUnion([
          {
            'action': action,
            'at': FieldValue.serverTimestamp(),
            'by': uid,
          }
        ]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense $action successfully'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadExpense();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExpense,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final d = expense ?? {};
    final merchant = d['merchant'] ?? 'Unknown';
    final totalAmount = d['totalAmount'] ?? d['parsed']?['total'] ?? '-';
    final currency = d['currency'] ?? d['parsed']?['currency'] ?? '';
    final date = d['date'] ?? '-';
    final status = d['status'] ?? 'draft';
    final notes = d['notes'] ?? '';
    final attachments = (d['attachments'] as List?) ?? [];

    // Status color
    Color statusColor = Colors.grey;
    if (status == 'pending_approval') {
      statusColor = Colors.orange;
    } else if (status == 'approved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    }

    // Can approve/reject if pending
    final canApproveReject = status == 'pending_approval' && !isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: Text(merchant),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main details
            _DetailSection(
              title: 'Amount',
              child: Text(
                '$totalAmount ${currency.isNotEmpty ? currency.toUpperCase() : ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _DetailRow(label: 'Merchant', value: merchant),
            const SizedBox(height: 12),

            _DetailRow(label: 'Date', value: date),
            const SizedBox(height: 12),

            _DetailRow(
              label: 'Currency',
              value: currency.isNotEmpty ? currency.toUpperCase() : '-',
            ),
            const SizedBox(height: 24),

            // Notes
            if (notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(notes),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // OCR Data
            if (d['parsed'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OCR Extracted Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          label: 'Extracted Merchant',
                          value: d['parsed']['merchant'] ?? 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Extracted Total',
                          value: d['parsed']['total']?.toString() ?? 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Extracted Date',
                          value: d['parsed']['date'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Attachments
            if (attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...attachments.map<Widget>((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: const Icon(Icons.attachment),
                        title: Text(a['path']?.split('/').last ?? 'Attachment'),
                        subtitle: Text(
                          a['uploadedAt']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),

            // Audit trail
            if ((d['audit'] as List?)?.isNotEmpty == true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...((d['audit'] as List?) ?? []).map<Widget>((entry) {
                    final action = entry['action'] ?? 'unknown';
                    final timestamp = entry['at'] as Timestamp?;
                    final date = timestamp?.toDate().toString().split('.')[0] ?? 'N/A';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            action == 'approved'
                                ? Icons.check_circle
                                : action == 'rejected'
                                    ? Icons.cancel
                                    : Icons.info,
                            color: action == 'approved'
                                ? Colors.green
                                : action == 'rejected'
                                    ? Colors.red
                                    : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.replaceAll('_', ' ').capitalize(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),

            // Action buttons
            if (canApproveReject)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _updateExpenseStatus('rejected', 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _updateExpenseStatus('approved', 'approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              )
            else if (status != 'draft')
              Center(
                child: Text(
                  'This expense has been ${status.replaceAll('_', ' ')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
