import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/crm_model.dart';
import 'crm_contact_screen.dart';

class CrmContactDetail extends StatefulWidget {
  final String contactId;
  const CrmContactDetail({super.key, required this.contactId});

  @override
  State<CrmContactDetail> createState() => _CrmContactDetailState();
}

class _CrmContactDetailState extends State<CrmContactDetail> {
  Contact? _contact;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<CrmProvider>();
    try {
      final c = await provider.getContact(widget.contactId);
      setState(() {
        _contact = c;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading contact')));
    }
  }

  Future<void> _delete() async {
    final provider = context.read<CrmProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.deleteContact(widget.contactId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_contact == null) return const Scaffold(body: Center(child: Text('Contact not found')));

    final c = _contact!;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CrmContactScreen(contact: c))),
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(children: [
          ListTile(title: const Text('Company'), subtitle: Text(c.company.isNotEmpty ? c.company : '-')),
          ListTile(title: const Text('Job title'), subtitle: Text(c.jobTitle.isNotEmpty ? c.jobTitle : '-')),
          ListTile(title: const Text('Email'), subtitle: Text(c.email.isNotEmpty ? c.email : '-')),
          ListTile(title: const Text('Phone'), subtitle: Text(c.phone.isNotEmpty ? c.phone : '-')),
          const Divider(),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(c.notes.isNotEmpty ? c.notes : '-'),
        ]),
      ),
    );
  }
}