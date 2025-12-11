import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_movement_model.dart';
import '../../services/inventory_service.dart';
import '../../widgets/inventory/stock_adjust_modal.dart';

class InventoryItemDetailScreen extends StatefulWidget {
  final String itemId;

  const InventoryItemDetailScreen({Key? key, required this.itemId})
      : super(key: key);

  @override
  State<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen> {
  final InventoryService _service = InventoryService();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final itemRef = _service.inventoryCollection(uid).doc(widget.itemId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Simple edit: navigate to Add screen with existing values (not implemented full edit UI here)
              // For production, generate a full edit flow.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Edit flow TODO — will be generated on request'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              // quick adjust modal
              final res = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    StockAdjustModal(itemId: widget.itemId, uid: uid),
              );
              if (res == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock adjusted')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: itemRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Item not found'));
          }

          final item = InventoryItem.fromJson(
            snap.data!.data() as Map<String, dynamic>,
            snap.data!.id,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Item header with image and key info
              Row(
                children: [
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 36,
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 36,
                          child: Text(
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text('SKU: ${item.sku}'),
                        const SizedBox(height: 6),
                        Text('Supplier: ${item.supplierId ?? "—"}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.stockQuantity}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: item.stockQuantity <= item.minimumStock &&
                                  item.minimumStock > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Min: ${item.minimumStock}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_money),
                          const SizedBox(width: 8),
                          Text('Cost: €${item.costPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.price_check),
                          const SizedBox(width: 8),
                          Text(
                              'Sale: €${item.sellingPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.percent),
                          const SizedBox(width: 8),
                          Text('Tax: ${item.tax.toStringAsFixed(2)}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.trending_up),
                          const SizedBox(width: 8),
                          Text(
                            'Profit: €${item.profitPerUnit.toStringAsFixed(2)} (${item.profitMargin.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Stock movements header
              const Text(
                'Stock Movements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Stock movements list
              StreamBuilder<QuerySnapshot>(
                stream: itemRef
                    .collection('stock_movements')
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, mSnap) {
                  if (!mSnap.hasData) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = mSnap.data!.docs;
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No movements yet'),
                    );
                  }

                  final movements = docs
                      .map((d) => StockMovement.fromJson(
                            d.data() as Map<String, dynamic>,
                            d.id,
                          ))
                      .toList();

                  return Column(
                    children: movements.map((mv) {
                      final sign = mv.quantity >= 0 ? '+' : '';
                      final color = mv.quantity < 0 ? Colors.red : Colors.green;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Text(
                              mv.typeIcon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            mv.type,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Before: ${mv.before} → After: ${mv.after}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (mv.note != null && mv.note!.isNotEmpty)
                                Text(
                                  mv.note!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '$sign${mv.quantity}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
