import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildDashboardCard(context, 'Expenses', Icons.receipt, '/expense-scanner'),
          _buildDashboardCard(context, 'AI Assistant', Icons.smart_toy, '/ai-assistant'),
          _buildDashboardCard(context, 'CRM', Icons.people, '/crm'),
          _buildDashboardCard(context, 'Projects', Icons.work, '/projects'),
          _buildDashboardCard(context, 'Invoices', Icons.description, '/invoices'),
          _buildDashboardCard(context, 'Crypto', Icons.currency_bitcoin, '/crypto'),
        ],
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
