import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';
import 'add_inventory_item_screen.dart';
import 'inventory_item_detail_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _service = InventoryService();
  final TextEditingController _searchCtrl = TextEditingController();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
            ),
            tooltip: 'Add item',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.streamItems(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          final items = docs
              .map((d) => InventoryItem.fromJson(d.data() as Map<String, dynamic>, d.id))
              .toList();

          final query = _searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? items
              : items
                  .where((i) =>
                      i.name.toLowerCase().contains(query) ||
                      i.sku.toLowerCase().contains(query) ||
                      (i.barcode ?? '').toLowerCase().contains(query))
                  .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No items found'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add first item'),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddInventoryItemScreen())),
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final it = filtered[index];
              final low = it.minimumStock > 0 && it.stockQuantity <= it.minimumStock;

              return ListTile(
                leading: it.imageUrl != null && it.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          it.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            child: Text(it.name.isNotEmpty ? it.name[0].toUpperCase() : '?'),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        child: Text(
                            it.name.isNotEmpty ? it.name[0].toUpperCase() : '?'),
                      ),
                title: Text(it.name),
                subtitle: Text('SKU: ${it.sku} • ${it.category ?? '—'}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${it.stockQuantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: low ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '€${it.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                tileColor: low ? Colors.red.shade50 : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryItemDetailScreen(itemId: it.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
