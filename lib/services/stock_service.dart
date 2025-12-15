import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Stock/Inventory item model
class StockItem {
  final String id;
  final String userId;
  final String item;
  final int quantity;
  final double cost;
  final String? category;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime lastUpdated;

  StockItem({
    required this.id,
    required this.userId,
    required this.item,
    required this.quantity,
    required this.cost,
    this.category,
    this.location,
    this.notes,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'item': item,
    'quantity': quantity,
    'cost': cost,
    'category': category,
    'location': location,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  /// Create from Firestore JSON
  factory StockItem.fromJson(Map<String, dynamic> json, String id) {
    return StockItem(
      id: id,
      userId: json['userId'] ?? '',
      item: json['item'] ?? '',
      quantity: json['quantity'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
      category: json['category'],
      location: json['location'],
      notes: json['notes'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copy with modifications
  StockItem copyWith({
    String? item,
    int? quantity,
    double? cost,
    String? category,
    String? location,
    String? notes,
  }) {
    return StockItem(
      id: id,
      userId: userId,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
      category: category ?? this.category,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Service for managing stock/inventory
class StockService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add stock item
  Future<String> addStockItem({
    required String item,
    required int quantity,
    required double cost,
    String? category,
    String? location,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final stock = StockItem(
        id: '',
        userId: userId,
        item: item,
        quantity: quantity,
        cost: cost,
        category: category,
        location: location,
        notes: notes,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final docRef = await _firestore.collection('stock').add(stock.toJson());
      logger.info('Stock item added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger.error('Error adding stock item: $e');
      rethrow;
    }
  }

  /// Get all stock for user
  Future<List<StockItem>> getUserStock() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final snapshot = await _firestore
          .collection('stock')
          .where('userId', isEqualTo: userId)
          .orderBy('item')
          .get();

      return snapshot.docs
          .map((doc) => StockItem.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching stock: $e');
      rethrow;
    }
  }

  /// Update stock quantity
  Future<void> updateQuantity(String stockId, int newQuantity) async {
    try {
      await _firestore.collection('stock').doc(stockId).update({
        'quantity': newQuantity,
        'lastUpdated': Timestamp.now(),
      });
      logger.info('Stock quantity updated: $stockId');
    } catch (e) {
      logger.error('Error updating quantity: $e');
      rethrow;
    }
  }

  /// Update stock item
  Future<void> updateStockItem(String stockId, StockItem item) async {
    try {
      await _firestore.collection('stock').doc(stockId).update(item.toJson());
      logger.info('Stock item updated: $stockId');
    } catch (e) {
      logger.error('Error updating stock item: $e');
      rethrow;
    }
  }

  /// Delete stock item
  Future<void> deleteStockItem(String stockId) async {
    try {
      await _firestore.collection('stock').doc(stockId).delete();
      logger.info('Stock item deleted: $stockId');
    } catch (e) {
      logger.error('Error deleting stock item: $e');
      rethrow;
    }
  }

  /// Stream user's stock
  Stream<List<StockItem>> streamUserStock() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    return _firestore
        .collection('stock')
        .where('userId', isEqualTo: userId)
        .orderBy('item')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StockItem.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get low stock items (quantity < threshold)
  Future<List<StockItem>> getLowStockItems(int threshold) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final snapshot = await _firestore
          .collection('stock')
          .where('userId', isEqualTo: userId)
          .where('quantity', isLessThan: threshold)
          .get();

      return snapshot.docs
          .map((doc) => StockItem.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching low stock: $e');
      rethrow;
    }
  }

  /// Get total inventory value
  Future<double> getTotalInventoryValue() async {
    final stock = await getUserStock();
    return stock.fold(0, (sum, item) => sum + (item.quantity * item.cost));
  }
}
