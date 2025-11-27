import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/crm_provider.dart';
import '../../data/models/crm_model.dart';
import 'crm_list_screen.dart';
import 'crm_contact_screen.dart';
import 'crm_contact_detail.dart';

class CrmDashboardScreen extends StatelessWidget {
  const CrmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrmProvider>();
    final contacts = provider.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CRM Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrmContactScreen()),
            ),
          )
        ],
      ),

      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? _emptyState(context)
              : _dashboard(context, contacts),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("No contacts yet"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrmContactScreen()),
            ),
            child: const Text("Add your first contact"),
          )
        ],
      ),
    );
  }

  Widget _dashboard(BuildContext context, List<Contact> contacts) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Overview", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),

        _statsRow([
          _statCard("Total Contacts", contacts.length.toString(), Icons.people),
          _statCard("Companies", _countCompanies(contacts).toString(),
              Icons.apartment),
        ]),

        const SizedBox(height: 20),
        Text("Actions", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),

        _quickActionRow(context),

        const SizedBox(height: 20),
        Text("Recent Contacts", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),

        ...contacts.take(5).map((c) => _contactPreviewCard(context, c)),
      ],
    );
  }

  Widget _statsRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrmContactScreen()),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text("Add Contact"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrmListScreen()),
                ),
                icon: const Icon(Icons.list),
                label: const Text("View All"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/crm/insights'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("AI Insights"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contactPreviewCard(BuildContext context, Contact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
        ),
        title: Text(contact.name),
        subtitle: Text(contact.company.isNotEmpty ? contact.company : contact.email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CrmContactDetail(contactId: contact.id),
          ),
        ),
      ),
    );
  }

  int _countCompanies(List<Contact> contacts) {
    final companies = contacts
        .where((c) => c.company.isNotEmpty)
        .map((c) => c.company.toLowerCase())
        .toSet();
    return companies.length;
  }
}