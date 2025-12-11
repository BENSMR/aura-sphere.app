import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import 'status_badge_widget.dart';

/// Simple invoice row displaying amount and status
/// 
/// Example:
/// ```dart
/// InvoiceListRow(invoice: invoice)
/// ```
class InvoiceListRow extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const InvoiceListRow({
    Key? key,
    required this.invoice,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${invoice.currency}${invoice.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          statusBadge(invoice.status),
        ],
      ),
    );
  }
}

/// Extended invoice row with more details
/// 
/// Shows: Invoice ID | Amount | Status | Due Date
/// Example:
/// ```dart
/// InvoiceListRowExtended(invoice: invoice)
/// ```
class InvoiceListRowExtended extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final bool showDueDate;
  final bool showId;

  const InvoiceListRowExtended({
    Key? key,
    required this.invoice,
    this.onTap,
    this.showDueDate = true,
    this.showId = true,
  }) : super(key: key);

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days overdue';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else {
      return 'Due in ${difference.inDays} days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showId)
                    Text(
                      invoice.id,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.currency}${invoice.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              statusBadge(invoice.status),
            ],
          ),
          if (showDueDate) ...[
            const SizedBox(height: 8),
            Text(
              _formatDueDate(invoice.dueDate),
              style: TextStyle(
                fontSize: 12,
                color: _getDueDateColor(invoice.dueDate),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime? date) {
    if (date == null) return Colors.grey;
    final difference = date.difference(DateTime.now());
    
    if (difference.inDays < 0) {
      return Colors.red; // Overdue
    } else if (difference.inDays <= 3) {
      return Colors.orange; // Due soon
    }
    return Colors.green; // Plenty of time
  }
}

/// Invoice list tile with full details
/// 
/// Shows: ID | Amount | Status | Due Date | Payment Method
/// Example:
/// ```dart
/// InvoiceListTile(invoice: invoice, onTap: () { })
/// ```
class InvoiceListTile extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final EdgeInsets padding;

  const InvoiceListTile({
    Key? key,
    required this.invoice,
    this.onTap,
    this.onDelete,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPaymentMethodLabel(String? method) {
    if (method == null) return 'Not recorded';
    switch (method.toLowerCase()) {
      case 'credit_card':
        return '💳 Credit Card';
      case 'bank_transfer':
        return '🏦 Bank Transfer';
      case 'check':
        return '📋 Check';
      case 'cash':
        return '💵 Cash';
      case 'paypal':
        return 'PayPal';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice.id,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  statusBadge(invoice.status),
                ],
              ),
              const SizedBox(height: 12),
              // Amount and Due Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${invoice.currency}${invoice.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (invoice.dueDate != null)
                    Text(
                      _formatDate(invoice.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Payment info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getPaymentMethodLabel(invoice.paymentMethod),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (invoice.paymentDate != null)
                    Text(
                      'Paid: ${_formatDate(invoice.paymentDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (onDelete != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact invoice summary card
/// 
/// Perfect for dashboard views
class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final bool showPaymentInfo;

  const InvoiceCard({
    Key? key,
    required this.invoice,
    this.onTap,
    this.showPaymentInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  statusBadge(invoice.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${invoice.currency}${invoice.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showPaymentInfo && invoice.paymentDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Paid on ${invoice.paymentDate!.day}/${invoice.paymentDate!.month}/${invoice.paymentDate!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
