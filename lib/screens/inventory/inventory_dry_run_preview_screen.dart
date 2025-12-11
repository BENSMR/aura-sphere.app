import 'package:flutter/material.dart';

class InventoryDryRunPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> dryRunData;

  const InventoryDryRunPreviewScreen({
    Key? key,
    required this.dryRunData,
  }) : super(key: key);

  Widget _buildDiff(Map<String, dynamic>? before, Map<String, dynamic>? after) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (before == null) ...[
          const Text("New item", style: TextStyle(color: Colors.green)),
        ] else ...[
          const Text("Existing item", style: TextStyle(color: Colors.blue)),
          Text("Before: Qty ${before['quantity'] ?? 0}", style: const TextStyle(color: Colors.redAccent)),
          Text("After: Qty ${after?['quantity'] ?? 0}", style: const TextStyle(color: Colors.green)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplier = dryRunData['supplierChanges'];
    final items = List<Map<String, dynamic>>.from(dryRunData['itemResults']);

    return Scaffold(
      appBar: AppBar(title: const Text("Preview Changes")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (supplier != null)
              Card(
                child: ListTile(
                  title: const Text("Supplier Changes"),
                  subtitle: Text(
                    supplier['createSupplier'] == true
                        ? "New supplier will be created"
                        : "Existing supplier will be reused",
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(it['after']['name']),
                      subtitle: _buildDiff(it['before'], it['after']),
                      trailing: Text(it['type'] == 'create' ? "NEW" : "UPDATE"),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("CONFIRM & APPLY"),
              onPressed: () {
                Navigator.pop(context, true); // confirm → run real function
              },
            )
          ],
        ),
      ),
    );
  }
}
