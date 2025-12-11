import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/purchase_order.dart';

class POReceiveScreen extends StatefulWidget {
  final PurchaseOrder po;
  const POReceiveScreen({Key? key, required this.po}) : super(key: key);

  @override
  State<POReceiveScreen> createState() => _POReceiveScreenState();
}

class _POReceiveScreenState extends State<POReceiveScreen> {
  final Map<int, TextEditingController> controllers = {};
  bool processing = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.po.items.length; i++) {
      final remaining =
          (widget.po.items[i].qtyOrdered - widget.po.items[i].qtyReceived);
      controllers[i] = TextEditingController(
        text: remaining > 0 ? remaining.toString() : '0',
      );
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _dryRun() async {
    final functions = FirebaseFunctions.instance;
    final items = _buildReceivedItems();

    try {
      // Optional: implement dryRunPurchaseOrderApply on server
      // For now, just show preview dialog
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Receive Preview'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Items to receive:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final itemIdx = item['itemIndex'] as int;
                    final poItem = widget.po.items[itemIdx];
                    final qty = item['qtyReceived'] as int;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${poItem.name}: $qty ${poItem.unit ?? 'pcs'}',
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    'Total items: ${items.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              )
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview error: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _buildReceivedItems() {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < widget.po.items.length; i++) {
      final qty = int.tryParse(controllers[i]!.text) ?? 0;
      if (qty > 0) {
        items.add({
          'itemIndex': i,
          'qtyReceived': qty,
          'costPrice': widget.po.items[i].costPrice,
        });
      }
    }
    return items;
  }

  Future<void> _confirmReceive() async {
    final items = _buildReceivedItems();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one item quantity')),
      );
      return;
    }

    setState(() => processing = true);
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('receivePurchaseOrder');
      await callable.call({
        'poId': widget.po.id,
        'receivedItems': items,
      });

      if (!mounted) return;
      Navigator.pop(context, true); // success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receive failed: $e')),
      );
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Goods'),
        subtitle: Text('PO: ${widget.po.poNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.po.items.length,
                itemBuilder: (_, i) {
                  final it = widget.po.items[i];
                  final remaining = it.qtyOrdered - it.qtyReceived;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${it.sku ?? 'N/A'} • Ordered: ${it.qtyOrdered} • Already received: ${it.qtyReceived}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (it.costPrice != null)
                            Text(
                              'Cost: \$${it.costPrice?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Receive qty:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: controllers[i],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Max: $remaining',
                                    border: OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: processing ? null : _dryRun,
                    child: const Text('Preview Changes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: processing ? null : _confirmReceive,
                    child: processing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Receive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
