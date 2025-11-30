// lib/screens/invoice/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice/invoice_service.dart';
import '../../providers/invoice_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({Key? key, required this.invoice}) : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final InvoiceService _svc = InvoiceService();
  bool loading = false;

  Future<void> _payNow() async {
    setState(() => loading = true);
    try {
      final url = await _svc.createPaymentLink(widget.invoice.id,
          successUrl: 'https://yourapp.com/payment-success',
          cancelUrl: 'https://yourapp.com/payment-cancel');
      if (url != null && url.isNotEmpty) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment URL not available')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return Scaffold(
      appBar: AppBar(title: Text(inv.invoiceNumber)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${inv.clientId}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Issue Date: ${inv.issueDate.toLocal()}'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: inv.items.map((it) => ListTile(
                  title: Text(it.description),
                  subtitle: Text('${it.quantity} x ${it.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text((it.total).toStringAsFixed(2)),
                )).toList(),
              ),
            ),
            const Divider(),
            Text('Amount: ${inv.amount.toStringAsFixed(2)} ${inv.currency}'),
            Text('Total: ${inv.amount.toStringAsFixed(2)} ${inv.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (inv.paymentStatus != 'paid') ...[
              loading ? const Center(child: CircularProgressIndicator()) :
              ElevatedButton.icon(onPressed: _payNow, icon: const Icon(Icons.payment), label: const Text('Pay now')),
            ] else ...[
              const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Paid')])
            ]
          ],
        ),
      ),
    );
  }
}
