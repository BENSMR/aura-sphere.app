import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _prefixController = TextEditingController();
  final _nextNumberController = TextEditingController();
  String _resetRule = 'none';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('invoice_settings')
        .get();
    final data = doc.exists ? doc.data()! : {};
    _prefixController.text = data['prefix'] ?? 'AURA-';
    _nextNumberController.text = (data['nextNumber']?.toString() ?? '1000');
    _resetRule = data['resetRule'] ?? 'none';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prefix = _prefixController.text.trim();
    final nextNumber = int.tryParse(_nextNumberController.text.trim()) ?? 1;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('invoice_settings')
        .set(
          {
            'prefix': prefix,
            'nextNumber': nextNumber,
            'resetRule': _resetRule,
            'lastReset': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Settings')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _prefixController,
                    decoration:
                        InputDecoration(labelText: 'Prefix (e.g. AURA-)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nextNumberController,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: 'Next number (integer)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _resetRule,
                    items: [
                      DropdownMenuItem(
                          value: 'none', child: Text('No reset')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Reset monthly')),
                      DropdownMenuItem(
                          value: 'yearly', child: Text('Reset yearly')),
                    ],
                    onChanged: (v) =>
                        setState(() => _resetRule = v ?? 'none'),
                    decoration: InputDecoration(labelText: 'Reset rule'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _save, child: Text('Save')),
                  const SizedBox(height: 12),
                  Text('Example preview:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final ex = _prefixController.text +
                        _nextNumberController.text.padLeft(4, '0');
                    return Text(ex, style: TextStyle(fontSize: 18));
                  })
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }
}
