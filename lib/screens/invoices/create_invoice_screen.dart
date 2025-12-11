import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/invoice_service.dart';
import '../../data/models/client_model.dart';

/// Create Invoice Screen
/// 
/// Complete invoice creation form with client selection,
/// amount input, due date picker, and line items support
class CreateInvoiceScreen extends StatefulWidget {
  final String? initialClientId;

  const CreateInvoiceScreen({
    Key? key,
    this.initialClientId,
  }) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late InvoiceService _invoiceService;
  
  // Form state
  String? _selectedClientId;
  double _amountTotal = 0;
  DateTime? _dueDate;
  String _status = 'draft';
  String _notes = '';
  bool _isLoading = false;
  
  // Line items
  final List<InvoiceItem> _lineItems = [];
  bool _useLineItems = false;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
    _selectedClientId = widget.initialClientId;
  }

  /// Add line item to invoice
  void _addLineItem() {
    showDialog(
      context: context,
      builder: (ctx) => _AddLineItemDialog(
        onAdd: (item) {
          setState(() {
            _lineItems.add(item);
            _amountTotal = _lineItems.fold(0, (sum, item) => sum + item.total);
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  /// Remove line item
  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
      _amountTotal = _lineItems.fold(0, (sum, item) => sum + item.total);
    });
  }

  /// Create invoice
  Future<void> _createInvoice() async {
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      _showError('Please select a client');
      return;
    }

    if (_amountTotal <= 0) {
      _showError('Invoice amount must be greater than 0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoiceId = _useLineItems && _lineItems.isNotEmpty
          ? await _invoiceService.createClientInvoiceWithItems(
              clientId: _selectedClientId!,
              items: _lineItems,
              dueDate: _dueDate,
              status: _status,
              notes: _notes.isNotEmpty ? _notes : null,
            )
          : await _invoiceService.createClientInvoice(
              clientId: _selectedClientId!,
              amountTotal: _amountTotal,
              dueDate: _dueDate,
              status: _status,
              notes: _notes.isNotEmpty ? _notes : null,
            );

      if (!mounted) return;

      _showSuccess('Invoice created successfully!');
      
      // Wait a moment then pop
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(invoiceId);
      }
    } on ArgumentError catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error creating invoice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Selection
                    _buildSectionHeader('Select Client'),
                    const SizedBox(height: 12),
                    _buildClientSelector(),
                    const SizedBox(height: 24),

                    // Amount Section
                    _buildSectionHeader('Amount'),
                    const SizedBox(height: 12),
                    _buildAmountSection(),
                    const SizedBox(height: 24),

                    // Due Date Section
                    _buildSectionHeader('Due Date'),
                    const SizedBox(height: 12),
                    _buildDueDatePicker(),
                    const SizedBox(height: 24),

                    // Status Section
                    _buildSectionHeader('Status'),
                    const SizedBox(height: 12),
                    _buildStatusDropdown(),
                    const SizedBox(height: 24),

                    // Notes Section
                    _buildSectionHeader('Additional Notes'),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createInvoice,
                            icon: const Icon(Icons.check),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            label: const Text('Create Invoice'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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

  /// Build client selector
  Widget _buildClientSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedClientId,
        hint: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Select a client...'),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        items: const [], // Would be populated from client provider
        onChanged: (value) {
          setState(() => _selectedClientId = value);
        },
      ),
    );
  }

  /// Build amount section
  Widget _buildAmountSection() {
    return Column(
      children: [
        // Toggle between direct amount and line items
        Row(
          children: [
            Expanded(
              child: Text(
                _useLineItems ? 'Using line items' : 'Direct amount',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Switch(
              value: _useLineItems,
              onChanged: (value) {
                setState(() => _useLineItems = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_useLineItems) ...[
          // Direct amount input
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Invoice Amount (€) *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _amountTotal = double.tryParse(value) ?? 0;
              });
            },
          ),
        ] else ...[
          // Line items list
          if (_lineItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No items added yet'),
              ),
            )
          else
            Column(
              children: [
                ...List.generate(
                  _lineItems.length,
                  (index) => _buildLineItemCard(index),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            onPressed: _addLineItem,
          ),
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
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '€${_amountTotal.toStringAsFixed(2)}',
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
      ],
    );
  }

  /// Build line item card
  Widget _buildLineItemCard(int index) {
    final item = _lineItems[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} × €${item.unitPrice.toStringAsFixed(2)} = €${item.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeLineItem(index),
            ),
          ],
        ),
      ),
    );
  }

  /// Build due date picker
  Widget _buildDueDatePicker() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _dueDate == null
                ? 'No due date set'
                : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 16,
              color: _dueDate == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: const Text('Set Date'),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _dueDate ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _dueDate = date);
            }
          },
        ),
      ],
    );
  }

  /// Build status dropdown
  Widget _buildStatusDropdown() {
    const statuses = ['draft', 'sent', 'paid', 'overdue', 'cancelled', 'refunded'];
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: statuses
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(_formatStatus(status)),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _status = value);
        }
      },
    );
  }

  /// Build notes field
  Widget _buildNotesField() {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Add any additional information...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        setState(() => _notes = value);
      },
    );
  }

  /// Format status for display
  String _formatStatus(String status) {
    const statusIcons = {
      'draft': '📝 Draft',
      'sent': '📤 Sent',
      'paid': '✅ Paid',
      'overdue': '⚠️ Overdue',
      'cancelled': '❌ Cancelled',
      'refunded': '↩️ Refunded',
    };
    return statusIcons[status] ?? status;
  }
}

/// Add Line Item Dialog
class _AddLineItemDialog extends StatefulWidget {
  final Function(InvoiceItem) onAdd;

  const _AddLineItemDialog({
    required this.onAdd,
  });

  @override
  State<_AddLineItemDialog> createState() => _AddLineItemDialogState();
}

class _AddLineItemDialogState extends State<_AddLineItemDialog> {
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _add() {
    final description = _descriptionController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 1;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text);
    final tax = double.tryParse(_taxController.text);

    if (description.isEmpty) {
      _showError('Enter item description');
      return;
    }

    if (quantity <= 0) {
      _showError('Quantity must be greater than 0');
      return;
    }

    if (unitPrice <= 0) {
      _showError('Unit price must be greater than 0');
      return;
    }

    final item = InvoiceItem(
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      tax: tax,
    );

    widget.onAdd(item);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Line Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g., Web Development Services',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty *',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price *',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      hintText: '10',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      hintText: '19',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
