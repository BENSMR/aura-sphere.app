import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/crm_model.dart';
import 'crm_contact_screen.dart';
import 'crm_contact_detail.dart';

class CrmListScreen extends StatefulWidget {
  const CrmListScreen({super.key});
  @override
  _CrmListScreenState createState() => _CrmListScreenState();
}

class _CrmListScreenState extends State<CrmListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrmProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CrmContactScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => provider.setSearch(v),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.contacts.isEmpty
                    ? const Center(child: Text('No contacts yet — press + to add'))
                    : ListView.separated(
                        itemCount: provider.contacts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final Contact c = provider.contacts[i];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text('${c.company}${c.jobTitle.isNotEmpty ? ' • ${c.jobTitle}' : ''}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CrmContactDetail(contactId: c.id))),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}