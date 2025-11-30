// lib/screens/invoices/invoice_create_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/crm_model.dart';
import '../../data/models/invoice_model.dart';
import '../../services/invoices/invoice_service.dart';
import '../../services/invoice/invoice_number_service_static.dart';

class InvoiceCreateScreen extends StatefulWidget {
  final Contact contact;
  final String currentUserId;
  const InvoiceCreateScreen({Key? key, required this.contact, required this.currentUserId}) : super(key: key);

  @override
  _InvoiceCreateScreenState createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtl = TextEditingController(text: 'Service');
  final _qtyCtl = TextEditingController(text: '1');
  final _priceCtl = TextEditingController(text: '100.00');
  final _notesCtl = TextEditingController();
  String? _invoiceNumber;
  bool _loadingInvoiceNumber = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInvoiceNumber();
  }

  Future<void> _loadInvoiceNumber() async {
    setState(() => _loadingInvoiceNumber = true);
    try {
      final number = await InvoiceNumberService.getNextInvoiceNumber();
      setState(() => _invoiceNumber = number);
    } catch (e) {
      print('Error loading invoice number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load invoice number: $e')),
      );
    } finally {
      setState(() => _loadingInvoiceNumber = false);
    }
  }

  @override
  void dispose() {
    _itemNameCtl.dispose();
    _qtyCtl.dispose();
    _priceCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(widget.contact.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.contact.company.isNotEmpty ? '${widget.contact.company}\n${widget.contact.email}' : widget.contact.email),
                isThreeLine: true,
              ),
              SizedBox(height: 12),
              if (_loadingInvoiceNumber)
                Center(child: CircularProgressIndicator())
              else if (_invoiceNumber != null)
                TextFormField(
                  initialValue: _invoiceNumber,
                  decoration: InputDecoration(labelText: 'Invoice Number'),
                  readOnly: true,
                  enabled: false,
                )
              else
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Invoice Number',
                    errorText: 'Failed to generate invoice number',
                  ),
                  readOnly: true,
                  enabled: false,
                ),
              SizedBox(height: 12),
              TextFormField(controller: _itemNameCtl, decoration: InputDecoration(labelText: 'Item name')),
              SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _qtyCtl, decoration: InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _priceCtl, decoration: InputDecoration(labelText: 'Unit price'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
              ]),
              SizedBox(height: 8),
              TextFormField(controller: _notesCtl, decoration: InputDecoration(labelText: 'Notes (invoice memo)'), maxLines: 3),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_invoiceNumber == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice number not ready')),
                          );
                          return;
                        }
                        setState(() => _saving = true);

                        final qty = double.tryParse(_qtyCtl.text) ?? 1;
                        final price = double.tryParse(_priceCtl.text) ?? 0.0;
                        final items = [
                          InvoiceItem(
                            description: _itemNameCtl.text.trim(),
                            quantity: qty,
                            unitPrice: price,
                          )
                        ];

                        final invoice = InvoiceModel(
                          id: '',
                          userId: widget.currentUserId,
                          clientId: widget.contact.id,
                          clientName: widget.contact.name,
                          clientEmail: widget.contact.email,
                          items: items,
                          subtotal: qty * price,
                          tax: 0.0,
                          total: qty * price,
                          currency: 'EUR',
                          taxRate: 0.0,
                          status: 'draft',
                          createdAt: Timestamp.now(),
                          invoiceNumber: _invoiceNumber,
                          dueDate: DateTime.now().add(const Duration(days: 14)),
                          notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
                        );

                        try {
                          final res = await InvoiceService.createInvoice(invoice, generatePdf: true);
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created')));
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        } catch (e) {
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: _saving ? CircularProgressIndicator(color: Colors.white) : Text('Create & Generate PDF'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
