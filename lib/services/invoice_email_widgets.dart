import 'package:flutter/material.dart';
import '../../data/models/invoice_model.dart';
import '../../services/invoice_service.dart';

/// Send Invoice via Email Button
/// 
/// Simple button that sends an invoice to the client's email.
/// Shows loading state and handles errors.
class SendInvoiceEmailButton extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;

  const SendInvoiceEmailButton({
    required this.invoice,
    this.onSuccess,
    this.onError,
  });

  @override
  State<SendInvoiceEmailButton> createState() => _SendInvoiceEmailButtonState();
}

class _SendInvoiceEmailButtonState extends State<SendInvoiceEmailButton> {
  late InvoiceService _invoiceService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
  }

  Future<void> _sendInvoice() async {
    setState(() => _isLoading = true);

    try {
      await _invoiceService.sendInvoiceByEmail(widget.invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice sent to ${widget.invoice.clientEmail}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      widget.onSuccess?.call();
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $errorMsg'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      widget.onError?.call(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _sendInvoice,
      icon: _isLoading ? SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(Icons.email),
      label: Text(_isLoading ? 'Sending...' : 'Send Invoice'),
    );
  }
}

/// Payment Reminder Button
/// 
/// Sends a payment reminder for unpaid invoices.
/// Disabled if invoice is already paid.
class PaymentReminderButton extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;

  const PaymentReminderButton({
    required this.invoice,
    this.onSuccess,
    this.onError,
  });

  @override
  State<PaymentReminderButton> createState() => _PaymentReminderButtonState();
}

class _PaymentReminderButtonState extends State<PaymentReminderButton> {
  late InvoiceService _invoiceService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
  }

  Future<void> _sendReminder() async {
    setState(() => _isLoading = true);

    try {
      await _invoiceService.sendPaymentReminder(widget.invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder sent to ${widget.invoice.clientEmail}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      widget.onSuccess?.call();
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      widget.onError?.call(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.invoice.status.toLowerCase() == 'paid';

    return ElevatedButton.icon(
      onPressed: isPaid || _isLoading ? null : _sendReminder,
      icon: _isLoading ? SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(Icons.notification_important),
      label: Text(_isLoading ? 'Sending...' : 'Send Reminder'),
    );
  }
}

/// Invoice Action Menu
/// 
/// Dropdown menu with multiple invoice actions:
/// - Send Invoice Email
/// - Send Payment Reminder
/// - Save PDF
class InvoiceActionMenu extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceActionMenu({required this.invoice});

  @override
  State<InvoiceActionMenu> createState() => _InvoiceActionMenuState();
}

class _InvoiceActionMenuState extends State<InvoiceActionMenu> {
  late InvoiceService _invoiceService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
  }

  Future<void> _sendInvoice() async {
    _setLoading(true);
    try {
      await _invoiceService.sendInvoiceByEmail(widget.invoice);
      _showSuccess('Invoice sent to ${widget.invoice.clientEmail}');
    } catch (e) {
      _showError('Send failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _sendReminder() async {
    _setLoading(true);
    try {
      await _invoiceService.sendPaymentReminder(widget.invoice);
      _showSuccess('Reminder sent');
    } catch (e) {
      _showError('Reminder failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _savePdf() async {
    _setLoading(true);
    try {
      await _invoiceService.savePdfToDevice(widget.invoice);
      _showSuccess('PDF saved to device');
    } catch (e) {
      _showError('Save failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      enabled: !_isLoading,
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.email, size: 20),
              SizedBox(width: 12),
              Text('Send Invoice'),
            ],
          ),
          onTap: _sendInvoice,
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.notification_important, size: 20),
              SizedBox(width: 12),
              Text('Send Reminder'),
            ],
          ),
          enabled: widget.invoice.status.toLowerCase() != 'paid',
          onTap: widget.invoice.status.toLowerCase() != 'paid'
              ? _sendReminder
              : null,
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 12),
              Text('Save PDF'),
            ],
          ),
          onTap: _savePdf,
        ),
      ],
      child: Icon(Icons.more_vert),
    );
  }
}

/// Complete Invoice Detail Card with Email Integration
/// 
/// Shows invoice details with action buttons for emailing and PDFs.
class InvoiceDetailCardWithEmail extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailCardWithEmail({required this.invoice});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.amber;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = invoice.invoiceNumber ?? invoice.id;
    final createdDate =
        invoice.createdAt.toDate().toString().split(' ')[0];
    final dueDate = invoice.dueDate != null
        ? invoice.dueDate!.toLocal().toString().split(' ')[0]
        : 'N/A';

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with invoice number and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice $invoiceNumber',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      invoice.clientName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                InvoiceActionMenu(invoice: invoice),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 12),

            // Invoice details grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(createdDate),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(dueDate),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Amount and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Items summary
            Text(
              'Items (${invoice.items.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 8),
            ...invoice.items.take(3).map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${item.quantity}x ${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )),
            if (invoice.items.length > 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '+ ${invoice.items.length - 3} more',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SendInvoiceEmailButton(invoice: invoice),
                ),
                SizedBox(width: 8),
                if (invoice.status.toLowerCase() != 'paid')
                  Expanded(
                    child: PaymentReminderButton(invoice: invoice),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Usage Example - Full Screen
class InvoiceDetailScreenExample extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreenExample({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: InvoiceActionMenu(invoice: invoice),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InvoiceDetailCardWithEmail(invoice: invoice),
            // Add more invoice details below
          ],
        ),
      ),
    );
  }
}
