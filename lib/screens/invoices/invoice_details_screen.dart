import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/invoice_service.dart';
import '../../data/models/invoice_model.dart';

/// Invoice Details Screen
///
/// Complete invoice management including viewing details,
/// updating status, marking as paid, and managing payments
class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;
  final String clientId;
  final String userId;

  const InvoiceDetailsScreen({
    Key? key,
    required this.invoiceId,
    required this.clientId,
    required this.userId,
  }) : super(key: key);

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  late InvoiceService _invoiceService;
  late Future<Map<String, dynamic>?> _invoiceFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
    _loadInvoice();
  }

  /// Load invoice data
  void _loadInvoice() {
    _invoiceFuture = _invoiceService.getInvoiceById(
      widget.invoiceId,
    );
  }

  /// Mark invoice as paid
  Future<void> _markAsPaid() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Paid?',
      message:
          'This will update the invoice status and trigger client metrics update.',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await _invoiceService.markInvoicePaid(widget.invoiceId);
      _showSuccess('Invoice marked as paid');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadInvoice();
      });
    } catch (e) {
      _showError('Error marking as paid: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Mark invoice as unpaid
  Future<void> _markAsUnpaid() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Unpaid?',
      message: 'This will revert the invoice to pending status.',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await _invoiceService.markInvoiceUnpaid(widget.invoiceId);
      _showSuccess('Invoice marked as unpaid');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadInvoice();
      });
    } catch (e) {
      _showError('Error marking as unpaid: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Update invoice status
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      await _invoiceService.updateInvoiceStatus(
        widget.invoiceId,
        newStatus,
      );
      _showSuccess('Status updated to $newStatus');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadInvoice();
      });
    } catch (e) {
      _showError('Error updating status: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Show payment modal
  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaymentModal(
        invoiceId: widget.invoiceId,
        onPaymentRecorded: () {
          Navigator.pop(ctx);
          _loadInvoice();
          _showSuccess('Payment recorded successfully');
        },
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadInvoice()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Invoice not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final invoice = snapshot.data!;
          final status = invoice['status'] ?? 'draft';
          final amountTotal = (invoice['amountTotal'] ?? 0).toDouble();
          final createdAt = invoice['createdAt'];
          final paidAt = invoice['paidAt'];
          final dueDate = invoice['dueDate'];
          final invoiceNumber = invoice['invoiceNumber'] ?? 'N/A';
          final notes = invoice['notes'] ?? '';

          return _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Status Header
                      _buildStatusHeader(status, amountTotal),

                      // Invoice Information
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Invoice Number and Dates
                            _buildInfoSection(
                              title: 'Invoice Information',
                              items: {
                                'Invoice #': invoiceNumber,
                                'Created': _formatDate(createdAt),
                                if (dueDate != null)
                                  'Due Date': _formatDate(dueDate),
                                if (paidAt != null)
                                  'Paid On': _formatDate(paidAt),
                              },
                            ),
                            const SizedBox(height: 24),

                            // Amount Details
                            _buildAmountSection(invoice),
                            const SizedBox(height: 24),

                            // Notes
                            if (notes.isNotEmpty) ...[
                              _buildSectionHeader('Notes'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(notes),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Action Buttons
                            _buildActionButtons(status),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  /// Build status header
  Widget _buildStatusHeader(String status, double amount) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      color: statusInfo['color'] as Color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusInfo['icon'] as IconData,
                  color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatStatus(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusInfo['subtitle'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build info section
  Widget _buildInfoSection(
    String title, {
    required Map<String, String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        const SizedBox(height: 8),
        ...items.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                entry.value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Build amount section
  Widget _buildAmountSection(Map<String, dynamic> invoice) {
    final items = invoice['items'] as List<dynamic>?;
    final amountTotal = (invoice['amountTotal'] ?? 0).toDouble();

    if (items == null || items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Amount Details'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount'),
              Text(
                '€${amountTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    }

    // Calculate totals from items
    double subtotal = 0;
    double discountTotal = 0;
    double taxTotal = 0;

    for (final item in items) {
      final itemData = item is Map ? item : {};
      final quantity = (itemData['quantity'] ?? 1).toDouble();
      final unitPrice = (itemData['unitPrice'] ?? 0).toDouble();
      final discountPct = (itemData['discount'] ?? 0).toDouble();
      final taxPct = (itemData['tax'] ?? 0).toDouble();

      final lineSubtotal = quantity * unitPrice;
      subtotal += lineSubtotal;
      discountTotal += lineSubtotal * (discountPct / 100);
      taxTotal += lineSubtotal * (taxPct / 100);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Line Items'),
        const SizedBox(height: 8),
        ...List.generate(
          items.length,
          (index) => _buildLineItemRow(items[index]),
        ),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal'),
            Text('€${subtotal.toStringAsFixed(2)}'),
          ],
        ),
        if (discountTotal > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount'),
              Text(
                '-€${discountTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ],
        if (taxTotal > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax'),
              Text('€${taxTotal.toStringAsFixed(2)}'),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '€${amountTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build line item row
  Widget _buildLineItemRow(dynamic item) {
    final itemData = item is Map ? item : {};
    final description = itemData['description'] ?? 'Item';
    final quantity = itemData['quantity'] ?? 1;
    final unitPrice = (itemData['unitPrice'] ?? 0).toDouble();
    final subtotal = quantity * unitPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$quantity × €${unitPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '€${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(String status) {
    return Column(
      children: [
        // Primary action based on status
        if (status == 'draft') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Sent'),
              onPressed: () => _updateStatus('sent'),
            ),
          ),
          const SizedBox(height: 8),
        ] else if (status == 'sent' || status == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.paid),
              label: const Text('Mark as Paid'),
              onPressed: _markAsPaid,
            ),
          ),
          const SizedBox(height: 8),
        ] else if (status == 'overdue') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.paid),
              label: const Text('Receive Payment'),
              onPressed: _showPaymentModal,
            ),
          ),
          const SizedBox(height: 8),
        ] else if (status == 'paid') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.undo),
              label: const Text('Mark as Unpaid'),
              onPressed: _markAsUnpaid,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Status dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: status,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('📝 Draft')),
              DropdownMenuItem(value: 'sent', child: Text('📤 Sent')),
              DropdownMenuItem(value: 'pending', child: Text('⏳ Pending')),
              DropdownMenuItem(value: 'paid', child: Text('✅ Paid')),
              DropdownMenuItem(value: 'overdue', child: Text('⚠️ Overdue')),
              DropdownMenuItem(value: 'cancelled', child: Text('❌ Cancelled')),
              DropdownMenuItem(value: 'refunded', child: Text('↩️ Refunded')),
            ],
            onChanged: (value) {
              if (value != null && value != status) {
                _updateStatus(value);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  /// Get status info (color, icon, subtitle)
  Map<String, dynamic> _getStatusInfo(String status) {
    const statusMap = {
      'draft': {
        'color': Colors.grey,
        'icon': Icons.draft_outline,
        'subtitle': 'Not yet sent to client',
      },
      'sent': {
        'color': Colors.blue,
        'icon': Icons.mail_outline,
        'subtitle': 'Awaiting payment',
      },
      'pending': {
        'color': Colors.orange,
        'icon': Icons.schedule,
        'subtitle': 'Payment in progress',
      },
      'paid': {
        'color': Colors.green,
        'icon': Icons.check_circle,
        'subtitle': 'Payment received',
      },
      'overdue': {
        'color': Colors.red,
        'icon': Icons.warning,
        'subtitle': 'Payment overdue',
      },
      'cancelled': {
        'color': Colors.grey,
        'icon': Icons.cancel,
        'subtitle': 'Invoice cancelled',
      },
      'refunded': {
        'color': Colors.purple,
        'icon': Icons.undo,
        'subtitle': 'Payment refunded',
      },
    };

    return statusMap[status] ??
        {
          'color': Colors.grey,
          'icon': Icons.info,
          'subtitle': 'Unknown status',
        };
  }

  /// Format status for display
  String _formatStatus(String status) {
    const statusMap = {
      'draft': 'Draft',
      'sent': 'Sent',
      'pending': 'Pending Payment',
      'paid': 'Paid',
      'overdue': 'Overdue',
      'cancelled': 'Cancelled',
      'refunded': 'Refunded',
    };
    return statusMap[status] ?? status;
  }

  /// Format date for display
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}

/// Payment Modal
class _PaymentModal extends StatefulWidget {
  final String invoiceId;
  final VoidCallback onPaymentRecorded;

  const _PaymentModal({
    required this.invoiceId,
    required this.onPaymentRecorded,
  });

  @override
  State<_PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<_PaymentModal> {
  late InvoiceService _invoiceService;
  final _amountController = TextEditingController();
  final _methodController = TextEditingController();
  bool _isProcessing = false;

  final paymentMethods = ['Bank Transfer', 'Credit Card', 'Check', 'Cash', 'Other'];

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
    _methodController.text = paymentMethods[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Enter valid payment amount');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _invoiceService.recordInvoicePayment(
        widget.invoiceId,
        amount,
        _methodController.text,
      );
      widget.onPaymentRecorded();
    } catch (e) {
      _showError('Error recording payment: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (€) *',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _methodController.text,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: paymentMethods
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) _methodController.text = value;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _recordPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
