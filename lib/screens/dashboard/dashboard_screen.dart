import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIVE invoice preview
            if (invoices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Invoices",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...invoices.take(3).map(
                      (inv) => Card(
                        child: ListTile(
                          title: Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("${inv.amount} ${inv.currency}"),
                          trailing: Text(inv.paymentStatus.toUpperCase()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
            // Dashboard grid
            GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(context, 'Expenses', Icons.receipt, '/expense-scanner'),
                _buildDashboardCard(context, 'AI Assistant', Icons.smart_toy, '/ai-assistant'),
                _buildDashboardCard(context, 'CRM', Icons.people, '/crm'),
                _buildDashboardCard(context, 'Projects', Icons.work, '/projects'),
                _buildDashboardCard(context, 'Invoices', Icons.description, '/invoices'),
                _buildDashboardCard(context, 'Crypto', Icons.currency_bitcoin, '/crypto'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, String route) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
