import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditClientScreen extends StatefulWidget {
  final String clientId;

  const EditClientScreen({super.key, required this.clientId});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String getCurrentUserId() => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    final uid = getCurrentUserId();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(widget.clientId)
        .get();

    if (!doc.exists) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final data = doc.data()!;

    nameCtrl.text = data['name'] ?? '';
    emailCtrl.text = data['email'] ?? '';
    phoneCtrl.text = data['phone'] ?? '';
    companyCtrl.text = data['company'] ?? '';
    addressCtrl.text = data['address'] ?? '';
    notesCtrl.text = data['notes'] ?? '';

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final uid = getCurrentUserId();
      final clientRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('clients')
          .doc(widget.clientId);

      // Update profile
      await clientRef.update({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'company': companyCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'notes': notesCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Add timeline event
      await clientRef.update({
        'timeline': FieldValue.arrayUnion([
          {
            'type': 'profile_updated',
            'message': 'Client profile updated.',
            'createdAt': FieldValue.serverTimestamp(),
          }
        ])
      });

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteClient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${'${nameCtrl.text}'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final uid = getCurrentUserId();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('clients')
            .doc(widget.clientId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client deleted'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    companyCtrl.dispose();
    addressCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteClient,
            tooltip: 'Delete client',
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'Save changes',
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field('Name', nameCtrl, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name required';
                return null;
              }),
              _field('Email', emailCtrl, validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Invalid email format';
                }
                return null;
              }),
              _field('Phone', phoneCtrl),
              _field('Company', companyCtrl),
              _field('Address', addressCtrl),
              _field('Notes', notesCtrl, maxLines: 3),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                onPressed: _saving ? null : _save,
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Client'),
                onPressed: _saving ? null : _deleteClient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : maxLines,
        validator: validator,
        enabled: !_saving,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
