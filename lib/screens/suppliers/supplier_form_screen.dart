import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? editing;
  const SupplierFormScreen({Key? key, this.editing}) : super(key: key);

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _currency = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _leadTime = TextEditingController();
  final _notes = TextEditingController();
  bool _preferred = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _email.text = e.email ?? '';
      _phone.text = e.phone ?? '';
      _contact.text = e.contact ?? '';
      _address.text = e.address ?? '';
      _currency.text = e.currency ?? '';
      _paymentTerms.text = e.paymentTerms ?? '';
      _leadTime.text = e.leadTimeDays?.toString() ?? '';
      _notes.text = e.notes ?? '';
      _preferred = e.preferred;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _contact.dispose();
    _address.dispose();
    _currency.dispose();
    _paymentTerms.dispose();
    _leadTime.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      'name': _name.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'contact': _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'currency': _currency.text.trim().isEmpty ? null : _currency.text.trim(),
      'paymentTerms': _paymentTerms.text.trim().isEmpty ? null : _paymentTerms.text.trim(),
      'leadTimeDays': int.tryParse(_leadTime.text),
      'preferred': _preferred,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'tags': [],
    };

    try {
      final prov = Provider.of<SupplierProvider>(context, listen: false);
      if (widget.editing == null) {
        await prov.add(payload);
      } else {
        await prov.update(widget.editing!.id, payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(labelText: 'Contact person'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _paymentTerms,
                  decoration: const InputDecoration(labelText: 'Payment terms'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _leadTime,
                  decoration: const InputDecoration(labelText: 'Lead time (days)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CheckboxListTile(
                  value: _preferred,
                  title: const Text('Preferred'),
                  onChanged: (v) {
                    setState(() => _preferred = v ?? false);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save supplier'),
            )
          ]),
        ),
      ),
    );
  }
}
