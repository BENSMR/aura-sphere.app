import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aurasphere_pro/models/inventory_item_model.dart';
import 'package:aurasphere_pro/models/stock_movement_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // 📦 Get all inventory items (real-time stream)
  Stream<List<InventoryItem>> streamInventoryItems() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('inventory/items')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    }).handleError((error) {
      return <InventoryItem>[];
    });
  }

  // 🔍 Search inventory items
  Stream<List<InventoryItem>> searchInventoryItems(String query) {
    if (_userId.isEmpty) return Stream.value([]);
    if (query.isEmpty) return streamInventoryItems();

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('inventory/items')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => InventoryItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by name, SKU, or barcode
      return items
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.sku.toLowerCase().contains(query.toLowerCase()) ||
              (item.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }).handleError((error) {
      return <InventoryItem>[];
    });
  }

  // 🔢 Get low stock items
  Stream<List<InventoryItem>> streamLowStockItems() {
    if (_userId.isEmpty) return Stream.value([]);

    return streamInventoryItems().map((items) {
      return items.where((item) => item.isLowStock).toList();
    });
  }

  // ➕ Create new inventory item
  Future<String> createInventoryItem({
    required String name,
    required String sku,
    String? barcode,
    String? imageUrl,
    String? category,
    String? brand,
    String? supplierId,
    required double costPrice,
    required double sellingPrice,
    required double tax,
    required int stockQuantity,
    required int minimumStock,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .add({
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'category': category,
        'brand': brand,
        'supplierId': supplierId,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'tax': tax,
        'stockQuantity': stockQuantity,
        'minimumStock': minimumStock,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
    }
  }

  // ✏️ Update inventory item
  Future<void> updateInventoryItem({
    required String itemId,
    String? name,
    String? sku,
    String? barcode,
    String? imageUrl,
    String? category,
    String? brand,
    String? supplierId,
    double? costPrice,
    double? sellingPrice,
    double? tax,
    int? minimumStock,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updateData['name'] = name;
      if (sku != null) updateData['sku'] = sku;
      if (barcode != null) updateData['barcode'] = barcode;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (category != null) updateData['category'] = category;
      if (brand != null) updateData['brand'] = brand;
      if (supplierId != null) updateData['supplierId'] = supplierId;
      if (costPrice != null) updateData['costPrice'] = costPrice;
      if (sellingPrice != null) updateData['sellingPrice'] = sellingPrice;
      if (tax != null) updateData['tax'] = tax;
      if (minimumStock != null) updateData['minimumStock'] = minimumStock;

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .doc(itemId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  // 📦 Record stock movement
  Future<void> recordStockMovement({
    required String itemId,
    required String type, // purchase, sale, refund, adjust, damage, transfer
    required int quantity,
    int? before,
    String? referenceId,
    String? note,
  }) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      // Get current item
      final itemDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) throw Exception('Item not found');

      final item = InventoryItem.fromJson(itemDoc.data() as Map<String, dynamic>, itemId);
      final currentStock = before ?? item.stockQuantity;

      // Calculate new stock based on movement type
      int newStock = currentStock;
      if (type.toLowerCase() == 'purchase' || type.toLowerCase() == 'refund') {
        newStock = currentStock + quantity;
      } else if (type.toLowerCase() == 'sale' || type.toLowerCase() == 'damage') {
        newStock = (currentStock - quantity).clamp(0, currentStock);
      } else if (type.toLowerCase() == 'adjust') {
        newStock = quantity; // Direct adjustment
      }

      // Record movement
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/movements')
          .add({
        'itemId': itemId,
        'type': type,
        'quantity': quantity,
        'before': currentStock,
        'after': newStock,
        'referenceId': referenceId,
        'note': note,
        'createdAt': Timestamp.now(),
      });

      // Update item stock
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .doc(itemId)
          .update({
        'stockQuantity': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to record stock movement: $e');
    }
  }

  // 📜 Get stock movements for item
  Stream<List<StockMovement>> streamStockMovements(String itemId) {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('inventory/movements')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StockMovement.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    }).handleError((error) {
      return <StockMovement>[];
    });
  }

  // 🗑️ Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  // 📊 Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('inventory/items')
          .get();

      final items = snapshot.docs
          .map((doc) => InventoryItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (items.isEmpty) {
        return {
          'totalItems': 0,
          'totalValue': 0.0,
          'lowStockCount': 0,
          'averageStockLevel': 0.0,
        };
      }

      final totalValue = items.fold<double>(0, (total, item) => total + item.stockValue);
      final lowStockCount = items.where((item) => item.isLowStock).length;
      final avgStock = items.fold<int>(0, (total, item) => total + item.stockQuantity) / items.length;

      return {
        'totalItems': items.length,
        'totalValue': totalValue,
        'lowStockCount': lowStockCount,
        'averageStockLevel': avgStock.toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to get inventory stats: $e');
    }
  }
}
