// lib/screens/invoice/create_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice/invoice_service.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_model.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({Key? key}) : super(key: key);

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _svc = InvoiceService();
  List<InvoiceItem> items = [];
  String customerName = '';
  String currency = 'EUR';
  DateTime dueDate = DateTime.now().add(Duration(days: 30));
  bool saving = false;

  @override
  void initState() {
    super.initState();
    items.add(InvoiceItem(name: 'New item', unitPrice: 0.0));
  }

  void _addItem() {
    setState(() {
      items.add(InvoiceItem(name: 'Item ${items.length + 1}', unitPrice: 0.0));
    });
  }

  Future<void> _saveDraft() async {
    setState(() => saving = true);
    try {
      final invNum = await _svc.generateInvoiceNumber();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final invoice = Invoice(
        id: id,
        userId: '',
        clientId: customerName,
        invoiceNumber: invNum,
        amount: items.fold<double>(0, (p, e) => p + (e.unitPrice * e.quantity)),
        currency: currency,
        status: 'draft',
        issueDate: DateTime.now(),
        dueDate: dueDate,
        items: items,
      );
      final idSaved = await _svc.createInvoiceDraft(invoice);
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice saved (#$invNum)')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);
    final subtotal = provider.computeSubtotal(items);
    final vat = provider.computeTotalVat(items);
    final total = provider.computeTotal(items);

    return Scaffold(
      appBar: AppBar(title: Text('Create Invoice')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Customer name'),
            onChanged: (v) => customerName = v,
          ),
          SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final it = entry.value;
            return Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Item name'),
                      onChanged: (v) => setState(() => it.name = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Qty'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) =>
                                setState(() => it.quantity = int.tryParse(v) ?? 1),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Unit price'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) =>
                                setState(() => it.unitPrice = double.tryParse(v) ?? 0.0),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'VAT %'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setState(() => it.vatRate = double.tryParse(v) ?? 0.0),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: Icon(Icons.add),
            label: Text('Add item'),
          ),
          SizedBox(height: 20),
          Text('Subtotal: ${subtotal.toStringAsFixed(2)} $currency'),
          Text('VAT: ${vat.toStringAsFixed(2)} $currency'),
          Text(
            'Total: ${total.toStringAsFixed(2)} $currency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          if (saving) Center(child: CircularProgressIndicator()),
          if (!saving)
            ElevatedButton(
              onPressed: _saveDraft,
              child: Text('Save invoice'),
            ),
        ],
      ),
    );
  }
}
