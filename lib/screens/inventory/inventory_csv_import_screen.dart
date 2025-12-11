import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';

class InventoryCSVImportScreen extends StatefulWidget {
  const InventoryCSVImportScreen({Key? key}) : super(key: key);
  @override
  State<InventoryCSVImportScreen> createState() => _InventoryCSVImportScreenState();
}

class _InventoryCSVImportScreenState extends State<InventoryCSVImportScreen> {
  final functions = FirebaseFunctions.instance;
  bool _loading = false;
  List<dynamic>? _items;

  Future<void> _pickAndParseCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null) return;
    final bytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
    final csv = utf8.decode(bytes);
    setState(() { _loading = true; _items = null; });
    try {
      final res = await functions.httpsCallable('importCSVInventory').call({'csv': csv});
      final data = res.data as Map<String, dynamic>;
      setState(() { _items = data['items'] as List<dynamic>; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parse error: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _commit() async {
    if (_items == null || _items!.isEmpty) return;
    try {
      final res = await functions.httpsCallable('intakeStockFromOCR').call({'items': _items, 'note': 'CSV import'});
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV imported')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commit error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSV Import')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ElevatedButton.icon(onPressed: _pickAndParseCsv, icon: const Icon(Icons.attach_file), label: const Text('Pick CSV')),
          if (_loading) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
          if (_items != null) Expanded(
            child: ListView.builder(
              itemCount: _items!.length,
              itemBuilder: (_, i) {
                final it = _items![i] as Map<String, dynamic>;
                return ListTile(title: Text(it['name'] ?? ''), subtitle: Text('SKU: ${it['sku'] ?? '-'}'), trailing: Text('x${it['quantity'] ?? 0}'));
              },
            ),
          ),
          if (_items != null && _items!.isNotEmpty) ElevatedButton.icon(onPressed: _commit, icon: const Icon(Icons.check), label: const Text('Commit to Inventory'))
        ]),
      ),
    );
  }
}
