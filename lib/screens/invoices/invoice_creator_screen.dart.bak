import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../data/models/invoice_model.dart';

class InvoiceCreatorScreen extends StatefulWidget {
  final String userId;
  final InvoiceModel? initialInvoice;

  const InvoiceCreatorScreen({
    super.key,
    required this.userId,
    this.initialInvoice,
  });

  @override
  State<InvoiceCreatorScreen> createState() => _InvoiceCreatorScreenState();
}

class _InvoiceCreatorScreenState extends State<InvoiceCreatorScreen> {
  late final TextEditingController _invoiceNumberCtrl;
  late final TextEditingController _clientNameCtrl;
  late final TextEditingController _clientEmailCtrl;
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _itemDescCtrl;
  late final TextEditingController _itemQtyCtrl;
  late final TextEditingController _itemPriceCtrl;
  late final TextEditingController _currencyCtrl;

  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _invoiceNumberCtrl = TextEditingController();
    _clientNameCtrl = TextEditingController();
    _clientEmailCtrl = TextEditingController();
    _clientIdCtrl = TextEditingController();
    _itemDescCtrl = TextEditingController();
    _itemQtyCtrl = TextEditingController(text: '1');
    _itemPriceCtrl = TextEditingController(text: '0.00');
    _currencyCtrl = TextEditingController(text: 'USD');

    // Initialize provider based on whether we're creating or editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InvoiceProvider>();
      if (widget.initialInvoice != null) {
        provider.startEditingInvoice(widget.initialInvoice!);
        _invoiceNumberCtrl.text = widget.initialInvoice!.invoiceNumber ?? '';
        _clientNameCtrl.text = widget.initialInvoice!.clientName;
        _clientEmailCtrl.text = widget.initialInvoice!.clientEmail;
        _clientIdCtrl.text = widget.initialInvoice!.clientId;
        _currencyCtrl.text = widget.initialInvoice!.currency;
        _selectedDueDate = widget.initialInvoice!.dueDate;
      } else {
        provider.startNewInvoice(widget.userId);
      }
    });
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _clientIdCtrl.dispose();
    _itemDescCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemPriceCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final description = _itemDescCtrl.text.trim();
    final quantity = double.tryParse(_itemQtyCtrl.text) ?? 1.0;
    final unitPrice = double.tryParse(_itemPriceCtrl.text) ?? 0.0;

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item description')),
      );
      return;
    }

    final provider = context.read<InvoiceProvider>();
    provider.addItemToEditing(
      InvoiceItem(
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
      ),
    );

    // Clear inputs
    _itemDescCtrl.clear();
    _itemQtyCtrl.text = '1';
    _itemPriceCtrl.text = '0.00';
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
      final provider = context.read<InvoiceProvider>();
      provider.setEditingDueDate(picked);
    }
  }

  Future<void> _saveAndSend(BuildContext context, {required bool sendEmail}) async {
    final provider = context.read<InvoiceProvider>();
    final editing = provider.editingInvoice;

    if (editing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invoice to save')),
      );
      return;
    }

    if (editing.clientName.isEmpty || editing.clientEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill client name and email')),
      );
      return;
    }

    if (editing.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final success = await provider.saveAndSendEditingInvoice(
      sendEmail: sendEmail,
      uploadPdf: true,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendEmail ? 'Invoice sent!' : 'Invoice saved!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider = context.read<InvoiceProvider>();
        provider.cancelEditingInvoice();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Invoice'),
          elevation: 0,
          actions: [
            Consumer<InvoiceProvider>(
              builder: (context, provider, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _saveAndSend(context, sendEmail: false),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _saveAndSend(context, sendEmail: true),
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Consumer<InvoiceProvider>(
          builder: (context, provider, _) {
            final editing = provider.editingInvoice;

            if (editing == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice number
                    TextFormField(
                      controller: _invoiceNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        hintText: 'INV-2024-001',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => provider.setEditingInvoiceNumber(v),
                    ),
                    const SizedBox(height: 16),

                    // Client section
                    const Text(
                      'Client Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        provider.setEditingClient(
                          id: _clientIdCtrl.text,
                          name: v,
                          email: _clientEmailCtrl.text,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) {
                        provider.setEditingClient(
                          id: _clientIdCtrl.text,
                          name: _clientNameCtrl.text,
                          email: v,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client ID (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        provider.setEditingClient(
                          id: v,
                          name: _clientNameCtrl.text,
                          email: _clientEmailCtrl.text,
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Items section
                    const Text(
                      'Invoice Items',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Items list
                    if (editing.items.isNotEmpty)
                      Card(
                        child: Column(
                          children: editing.items.asMap().entries.map((e) {
                            final idx = e.key;
                            final item = e.value;
                            return ListTile(
                              title: Text(item.description),
                              subtitle: Text(
                                'Qty: ${item.quantity.toStringAsFixed(2)} × '
                                '${editing.currency} ${item.unitPrice.toStringAsFixed(2)} = '
                                '${editing.currency} ${item.total.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => provider.removeItemFromEditing(idx),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Add item form
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Add Item',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _itemDescCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _itemQtyCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _itemPriceCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Price',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _addItem,
                                    child: const Text('Add'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invoice settings
                    const Text(
                      'Invoice Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Currency
                    TextFormField(
                      controller: _currencyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => provider.setEditingCurrency(v),
                    ),
                    const SizedBox(height: 12),

                    // Due date
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(
                        _selectedDueDate != null
                            ? '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDueDate,
                    ),
                    const SizedBox(height: 12),

                    // Tax rate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tax Rate'),
                                Text(
                                  '${(editing.taxRate * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Slider(
                              value: editing.taxRate,
                              onChanged: (v) => provider.setEditingTaxRate(v),
                              min: 0.0,
                              max: 0.5,
                              divisions: 50,
                              label: '${(editing.taxRate * 100).toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Totals
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                  '${editing.currency} ${editing.subtotal.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tax:'),
                                Text(
                                  '${editing.currency} ${editing.tax.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${editing.currency} ${editing.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Loading indicator
                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator()),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
