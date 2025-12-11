import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';

class StockAdjustModal extends StatefulWidget {
  final String itemId;
  final String uid;

  const StockAdjustModal({
    Key? key,
    required this.itemId,
    required this.uid,
  }) : super(key: key);

  @override
  State<StockAdjustModal> createState() => _StockAdjustModalState();
}

class _StockAdjustModalState extends State<StockAdjustModal> {
  final InventoryService _service = InventoryService();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _noteCtrl = TextEditingController();
  String _type = 'adjust';
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qtyText = _qtyCtrl.text.trim();
    if (qtyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quantity')),
      );
      return;
    }

    int? qty = int.tryParse(qtyText);
    if (qty == null || qty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a non-zero number')),
      );
      return;
    }

    // For outgoing types, make qty negative
    if (_type == 'damage' || _type == 'sale' || _type == 'transfer') {
      qty = -qty.abs();
    } else if (_type == 'purchase' || _type == 'refund') {
      qty = qty.abs();
    }

    setState(() => _saving = true);
    try {
      await _service.adjustStockCallable({
        'itemId': widget.itemId,
        'type': _type,
        'quantity': qty,
        'referenceId': null,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Adjust Stock',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Movement type dropdown
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: 'adjust',
                  child: Text('📝 Adjust (manual set)'),
                ),
                DropdownMenuItem(
                  value: 'purchase',
                  child: Text('📦 Purchase (incoming)'),
                ),
                DropdownMenuItem(
                  value: 'sale',
                  child: Text('🛒 Sale (outgoing)'),
                ),
                DropdownMenuItem(
                  value: 'refund',
                  child: Text('↩️ Refund (incoming)'),
                ),
                DropdownMenuItem(
                  value: 'damage',
                  child: Text('⚠️ Damage (outgoing)'),
                ),
                DropdownMenuItem(
                  value: 'transfer',
                  child: Text('🔄 Transfer (outgoing)'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'adjust'),
              decoration: InputDecoration(
                labelText: 'Movement Type',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quantity input
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note input
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g., Damaged in transit',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Type-specific helper text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTypeHint(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check),
                    onPressed: _saving ? null : _submit,
                    label: Text(_saving ? 'Applying...' : 'Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTypeHint() {
    switch (_type) {
      case 'adjust':
        return 'Directly set the quantity to a specific amount.';
      case 'purchase':
        return 'Increase stock when receiving items from supplier.';
      case 'sale':
        return 'Decrease stock when items are sold.';
      case 'refund':
        return 'Increase stock when customer returns items.';
      case 'damage':
        return 'Decrease stock for damaged or lost items.';
      case 'transfer':
        return 'Move stock between locations or warehouses.';
      default:
        return '';
    }
  }
}
