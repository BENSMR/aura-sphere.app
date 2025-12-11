import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import '../services/invoice_service.dart';

/// Dialog for entering partial payment amount
Future<double?> showAmountDialog(BuildContext context, {double maxAmount = 10000}) async {
  final controller = TextEditingController();
  double? result;

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Record Partial Payment'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Amount',
          hintText: 'Enter amount paid',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixText: '€ ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(controller.text);
            if (value == null || value <= 0) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }
            if (value > maxAmount) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('Amount cannot exceed €$maxAmount')),
              );
              return;
            }
            result = value;
            Navigator.pop(dialogContext);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}

/// Individual action button with loading state
class InvoiceActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const InvoiceActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  }) : super(key: key);

  @override
  State<InvoiceActionButton> createState() => _InvoiceActionButtonState();
}

class _InvoiceActionButtonState extends State<InvoiceActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label),
                ],
              ),
      ),
    );
  }

  Future<void> _handlePress() async {
    setState(() => _isLoading = true);
    try {
      widget.onPressed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Complete invoice action buttons widget
/// 
/// Provides buttons for:
/// - Mark as Paid
/// - Mark as Unpaid
/// - Record Partial Payment
/// - Set Due Date
class InvoiceActionButtons extends StatefulWidget {
  final InvoiceModel invoice;
  final InvoiceService invoiceService;
  final VoidCallback? onActionComplete;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;

  const InvoiceActionButtons({
    Key? key,
    required this.invoice,
    required this.invoiceService,
    this.onActionComplete,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  }) : super(key: key);

  @override
  State<InvoiceActionButtons> createState() => _InvoiceActionButtonsState();
}

class _InvoiceActionButtonsState extends State<InvoiceActionButtons> {
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAsPaid() async {
    _setLoading(true);
    try {
      await widget.invoiceService.markInvoicePaid(
        widget.invoice.id,
        'manual',
      );
      _showSnackBar('Invoice marked as paid');
      widget.onActionComplete?.call();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _markAsUnpaid() async {
    _setLoading(true);
    try {
      await widget.invoiceService.markInvoiceUnpaid(widget.invoice.id);
      _showSnackBar('Invoice marked as unpaid');
      widget.onActionComplete?.call();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _recordPartialPayment() async {
    final amount = await showAmountDialog(
      context,
      maxAmount: widget.invoice.total,
    );
    if (amount == null) return;

    _setLoading(true);
    try {
      await widget.invoiceService.recordPartialPayment(
        widget.invoice.id,
        amount,
      );
      _showSnackBar('Partial payment recorded: €$amount');
      widget.onActionComplete?.call();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _setDueDate() async {
    final due = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDate: widget.invoice.dueDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (due == null) return;

    _setLoading(true);
    try {
      await widget.invoiceService.setInvoiceDueDate(widget.invoice.id, due);
      _showSnackBar('Due date set to ${due.day}/${due.month}/${due.year}');
      widget.onActionComplete?.call();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = [
      if (!widget.invoice.isPaid)
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _markAsPaid,
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark as Paid'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      if (widget.invoice.isPaid)
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _markAsUnpaid,
          icon: const Icon(Icons.cancel),
          label: const Text('Mark as Unpaid'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
      if (!widget.invoice.isPaid)
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _recordPartialPayment,
          icon: const Icon(Icons.payment),
          label: const Text('Partial Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
          ),
        ),
      ElevatedButton.icon(
        onPressed: _isLoading ? null : _setDueDate,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Set Due Date'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      ),
    ];

    if (widget.direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: widget.mainAxisAlignment,
          children: widgets,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      );
    }
  }
}

/// Compact action button row for list items
class InvoiceActionRow extends StatefulWidget {
  final InvoiceModel invoice;
  final InvoiceService invoiceService;
  final VoidCallback? onActionComplete;

  const InvoiceActionRow({
    Key? key,
    required this.invoice,
    required this.invoiceService,
    this.onActionComplete,
  }) : super(key: key);

  @override
  State<InvoiceActionRow> createState() => _InvoiceActionRowState();
}

class _InvoiceActionRowState extends State<InvoiceActionRow> {
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _quickAction(String action) async {
    setState(() => _isLoading = true);
    try {
      if (action == 'paid') {
        await widget.invoiceService.markInvoicePaid(widget.invoice.id, 'manual');
        _showSnackBar('Marked as paid');
      } else if (action == 'unpaid') {
        await widget.invoiceService.markInvoiceUnpaid(widget.invoice.id);
        _showSnackBar('Marked as unpaid');
      }
      widget.onActionComplete?.call();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.invoice.isPaid)
          IconButton(
            onPressed: _isLoading ? null : () => _quickAction('paid'),
            icon: const Icon(Icons.check_circle),
            color: Colors.green,
            tooltip: 'Mark as Paid',
          ),
        if (widget.invoice.isPaid)
          IconButton(
            onPressed: _isLoading ? null : () => _quickAction('unpaid'),
            icon: const Icon(Icons.cancel),
            color: Colors.orange,
            tooltip: 'Mark as Unpaid',
          ),
        IconButton(
          onPressed: _isLoading ? null : () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Invoice Actions'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Delete'),
                      textColor: Colors.red,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Actions',
        ),
      ],
    );
  }
}
