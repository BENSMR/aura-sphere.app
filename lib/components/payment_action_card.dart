import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment action callbacks
typedef OnMarkPaidCallback = Future<void> Function();
typedef OnPartialPaymentCallback = Future<void> Function(double amount);
typedef OnPaymentMethodCallback = Future<void> Function(String method);

/// Calculates days until or since due date
int calculateDaysFromDue(DateTime? dueDate) {
  if (dueDate == null) return 0;
  final now = DateTime.now();
  return dueDate.difference(now).inDays;
}

String getDueStatusText(DateTime? dueDate) {
  if (dueDate == null) return 'No due date';
  final daysUntilDue = calculateDaysFromDue(dueDate);
  
  if (daysUntilDue > 0) {
    return 'Due in $daysUntilDue day${daysUntilDue != 1 ? 's' : ''}';
  } else if (daysUntilDue == 0) {
    return 'Due today';
  } else {
    return '${(-daysUntilDue)} day${-daysUntilDue != 1 ? 's' : ''} overdue';
  }
}

/// Payment status action card with buttons
class PaymentActionCard extends StatefulWidget {
  final String paymentStatus; // "unpaid" | "paid" | "overdue" | "partial"
  final DateTime? dueDate;
  final double amount;
  final String currency;
  final double? paidAmount;
  final OnMarkPaidCallback onMarkPaid;
  final OnPartialPaymentCallback? onPartialPayment;
  final VoidCallback? onEdit;

  const PaymentActionCard({
    Key? key,
    required this.paymentStatus,
    required this.dueDate,
    required this.amount,
    this.currency = '€',
    this.paidAmount,
    required this.onMarkPaid,
    this.onPartialPayment,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PaymentActionCard> createState() => _PaymentActionCardState();
}

class _PaymentActionCardState extends State<PaymentActionCard> {
  bool _isLoading = false;

  Future<void> _handleMarkPaid() async {
    setState(() => _isLoading = true);
    try {
      await widget.onMarkPaid();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePartialPayment() async {
    final amountController = TextEditingController(
      text: widget.paidAmount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Partial Payment'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount paid (${widget.currency})',
            border: const OutlineInputBorder(),
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid amount')),
                );
                return;
              }
              if (amount > widget.amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Amount exceeds invoice total')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await widget.onPartialPayment?.call(amount);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Partial payment recorded: ${widget.currency}${amount.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
              amountController.dispose();
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daysFromDue = calculateDaysFromDue(widget.dueDate);
    final dueText = getDueStatusText(widget.dueDate);
    final statusColor = _getStatusColor(widget.paymentStatus);
    final remainingAmount = widget.amount - (widget.paidAmount ?? 0);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and due date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Chip(
                        label: Text(
                          widget.paymentStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: statusColor,
                        side: BorderSide.none,
                        avatar: Icon(
                          _getStatusIcon(widget.paymentStatus),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Due date info
                      Text(
                        dueText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getDueTextColor(daysFromDue),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                // Amount remaining
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount Due',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.currency}${remainingAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: remainingAmount > 0 ? statusColor : Colors.green,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // Payment progress bar (if partial)
            if (widget.paidAmount != null && widget.paidAmount! > 0) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Progress',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${((widget.paidAmount! / widget.amount) * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.paidAmount! / widget.amount,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid: ${widget.currency}${widget.paidAmount!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade600,
                        ),
                  ),
                ],
              ),
            ],

            // Action buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mark as Paid button
                if (widget.paymentStatus != 'paid')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleMarkPaid,
                      icon: _isLoading
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                if (widget.paymentStatus != 'paid') const SizedBox(width: 12),

                // Partial Payment button
                if (widget.paymentStatus != 'paid' &&
                    widget.onPartialPayment != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handlePartialPayment,
                      icon: const Icon(Icons.payments),
                      label: const Text('Partial Payment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),

                // Edit button (always available)
                if (widget.onEdit != null)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: widget.onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'unpaid':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'partial':
        return Icons.pending_actions;
      case 'overdue':
        return Icons.dangerous;
      case 'unpaid':
      default:
        return Icons.pending;
    }
  }

  Color _getDueTextColor(int daysFromDue) {
    if (daysFromDue < 0) return Colors.red;
    if (daysFromDue <= 3) return Colors.orange;
    return Colors.green;
  }
}

/// Compact payment status row widget
class PaymentStatusRow extends StatelessWidget {
  final String status;
  final DateTime? dueDate;
  final bool showDaysLabel;

  const PaymentStatusRow({
    Key? key,
    required this.status,
    this.dueDate,
    this.showDaysLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysFromDue = calculateDaysFromDue(dueDate);
    final statusColor = _getStatusColor(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: statusColor,
          side: BorderSide.none,
        ),
        if (showDaysLabel && dueDate != null)
          Text(
            getDueStatusText(dueDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getDueTextColor(daysFromDue),
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'unpaid':
      default:
        return Colors.orange;
    }
  }

  Color _getDueTextColor(int daysFromDue) {
    if (daysFromDue < 0) return Colors.red;
    if (daysFromDue <= 3) return Colors.orange;
    return Colors.green;
  }
}
