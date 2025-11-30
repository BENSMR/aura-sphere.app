// lib/screens/invoice/invoice_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);
    if (provider.invoices.isEmpty && provider.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoices')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: ListView(
        children: provider.invoices.map((inv) {
          return ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv))),
            title: Text(inv.invoiceNumber + ' • ' + inv.clientId),
            subtitle: Text('${inv.amount.toStringAsFixed(2)} ${inv.currency}'),
            trailing: inv.paymentStatus == 'paid'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.timelapse, color: Colors.orange),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateInvoiceScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
