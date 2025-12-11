import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';
import 'inventory_dry_run_preview_screen.dart';

/// Usage:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => InventoryParsedReviewScreen(parsed: parsedMap)
/// ));
///
/// `parsed` structure: { "supplier": "ACME", "items": [ { "name": "...", "sku": "...", "quantity": 1, "costPrice": 1.0, "sellingPrice": 2.0, "tax": 0 } ] }
class InventoryParsedReviewScreen extends StatefulWidget {
  final Map<String, dynamic> parsed;
  final String? note;

  const InventoryParsedReviewScreen({Key? key, required this.parsed, this.note}) : super(key: key);

  @override
  State<InventoryParsedReviewScreen> createState() => _InventoryParsedReviewScreenState();
}

class _InventoryParsedReviewScreenState extends State<InventoryParsedReviewScreen> {
  final _functions = FirebaseFunctions.instance;
  final _supplierController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _supplierController.text = widget.parsed['supplier'] ?? '';
    final raw = widget.parsed['items'] as List<dynamic>? ?? [];
    // Normalize items into maps with required fields
    _items = raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {
        'name': (m['name'] ?? '').toString(),
        'sku': m['sku']?.toString(),
        'quantity': (m['quantity'] is num) ? (m['quantity'] as num).toInt() : int.tryParse('${m['quantity'] ?? 0}') ?? 0,
        'costPrice': (m['costPrice'] != null) ? double.tryParse('${m['costPrice']}') ?? null : null,
        'sellingPrice': (m['sellingPrice'] != null) ? double.tryParse('${m['sellingPrice']}') ?? null : null,
        'tax': (m['tax'] != null) ? double.tryParse('${m['tax']}') ?? null : null,
        'note': m['note'] ?? null,
      };
    }).toList();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    super.dispose();
  }

  void _addEmptyItem() {
    setState(() {
      _items.insert(0, {'name': '', 'sku': null, 'quantity': 1, 'costPrice': null, 'sellingPrice': null, 'tax': null, 'note': null});
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _editItemDialog(int index) async {
    final item = Map<String, dynamic>.from(_items[index]);
    final nameCtrl = TextEditingController(text: item['name'] ?? '');
    final skuCtrl = TextEditingController(text: item['sku'] ?? '');
    final qtyCtrl = TextEditingController(text: '${item['quantity'] ?? 0}');
    final costCtrl = TextEditingController(text: item['costPrice']?.toString() ?? '');
    final saleCtrl = TextEditingController(text: item['sellingPrice']?.toString() ?? '');
    final taxCtrl = TextEditingController(text: item['tax']?.toString() ?? '');
    final noteCtrl = TextEditingController(text: item['note']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU (optional)')),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost price (optional)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: saleCtrl, decoration: const InputDecoration(labelText: 'Selling price (optional)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: taxCtrl, decoration: const InputDecoration(labelText: 'Tax % (optional)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            // Validate basic
            if (nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
              return;
            }
            // Save changes into _items
            setState(() {
              _items[index] = {
                'name': nameCtrl.text.trim(),
                'sku': skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
                'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                'costPrice': double.tryParse(costCtrl.text),
                'sellingPrice': double.tryParse(saleCtrl.text),
                'tax': double.tryParse(taxCtrl.text),
                'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              };
            });
            Navigator.pop(ctx, true);
          }, child: const Text('Save'))
        ],
      ),
    );

    // cleanup controllers
    nameCtrl.dispose(); skuCtrl.dispose(); qtyCtrl.dispose(); costCtrl.dispose(); saleCtrl.dispose(); taxCtrl.dispose(); noteCtrl.dispose();
    if (result == true) {
      // item updated in state already
    }
  }

  Future<void> _commit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to commit')));
      return;
    }
    // Basic validation: every item must have a name and quantity >=0
    for (var it in _items) {
      if ((it['name'] ?? '').toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items must have a name')));
        return;
      }
      if ((it['quantity'] is int ? it['quantity'] as int : int.tryParse('${it['quantity'] ?? 0}') ?? 0) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity cannot be negative')));
        return;
      }
    }

    setState(() => _committing = true);
    try {
      // Step 1: Call dry run to preview changes
      final dryRunCallable = _functions.httpsCallable('dryRunInventoryChanges');
      final dryRunPayload = {
        'supplier': _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        'items': _items,
      };
      final dryRunRes = await dryRunCallable.call(dryRunPayload);
      final dryRunData = dryRunRes.data as Map<String, dynamic>?;

      if (dryRunData == null || dryRunData['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dry run failed')));
        return;
      }

      // Step 2: Show preview screen and wait for confirmation
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => InventoryDryRunPreviewScreen(dryRunData: dryRunData),
        ),
      );

      if (confirmed != true) {
        // User cancelled
        if (mounted) setState(() => _committing = false);
        return;
      }

      // Step 3: User confirmed, now run actual import
      final callable = _functions.httpsCallable('intakeStockFromOCR');
      final payload = {
        'supplier': _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        'items': _items,
        'note': widget.note ?? 'Imported via parsing',
      };
      final res = await callable.call(payload);
      final data = res.data as Map<String, dynamic>?;

      if (data != null && (data['success'] == true || data['ok'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory successfully updated')));
        Navigator.of(context).pop(true);
      } else {
        // show raw response for debugging
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import result: ${jsonEncode(data)}')));
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commit failed: $e')));
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Widget _buildItemTile(int idx) {
    final it = _items[idx];
    return Card(
      child: ListTile(
        title: Text(it['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('SKU: ${it['sku'] ?? '-'} • Price: ${it['sellingPrice']?.toString() ?? '-'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('x${it['quantity'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editItemDialog(idx)),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeItem(idx)),
          ],
        ),
        onTap: () => _editItemDialog(idx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _items.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review parsed items'),
        actions: [
          IconButton(onPressed: _addEmptyItem, icon: const Icon(Icons.add)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(
            controller: _supplierController,
            decoration: const InputDecoration(labelText: 'Supplier (detected)'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: itemCount == 0
                ? const Center(child: Text('No items parsed — add manually or retry parsing'))
                : ListView.builder(
                    itemCount: itemCount,
                    itemBuilder: (_, i) => _buildItemTile(i),
                  ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: _committing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                label: Text(_committing ? 'Committing...' : 'Add ${itemCount} item(s) to inventory'),
                onPressed: _committing ? null : _commit,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Tip: tap an item to edit details before committing', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
