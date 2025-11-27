import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_provider.dart';
import '../../data/models/crm_model.dart';

class CrmContactScreen extends StatefulWidget {
  final Contact? contact; // null => create

  const CrmContactScreen({super.key, this.contact});

  @override
  State<CrmContactScreen> createState() => _CrmContactScreenState();
}

class _CrmContactScreenState extends State<CrmContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _email, _phone, _company, _jobTitle, _notes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _email = widget.contact?.email ?? '';
    _phone = widget.contact?.phone ?? '';
    _company = widget.contact?.company ?? '';
    _jobTitle = widget.contact?.jobTitle ?? '';
    _notes = widget.contact?.notes ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _busy = true);
    final provider = context.read<CrmProvider>();
    try {
      if (widget.contact == null) {
        await provider.createContact(
          name: _name,
          email: _email,
          phone: _phone,
          company: _company,
          jobTitle: _jobTitle,
          notes: _notes,
        );
      } else {
        final updated = widget.contact!.copyWith(
          name: _name,
          email: _email,
          phone: _phone,
          company: _company,
          jobTitle: _jobTitle,
          notes: _notes,
        );
        await provider.updateContact(updated);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // show simple error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit contact' : 'New contact')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              onSaved: (v) => _name = v!.trim(),
            ),
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _email = v!.trim(),
            ),
            TextFormField(
              initialValue: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onSaved: (v) => _phone = v!.trim(),
            ),
            TextFormField(
              initialValue: _company,
              decoration: const InputDecoration(labelText: 'Company'),
              onSaved: (v) => _company = v!.trim(),
            ),
            TextFormField(
              initialValue: _jobTitle,
              decoration: const InputDecoration(labelText: 'Job title'),
              onSaved: (v) => _jobTitle = v!.trim(),
            ),
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 4,
              onSaved: (v) => _notes = v!.trim(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator() : Text(isEdit ? 'Save' : 'Create'),
            )
          ]),
        ),
      ),
    );
  }
}