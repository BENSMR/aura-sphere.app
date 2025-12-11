import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovement {
  final String id;
  final String itemId;
  final String type; // purchase, sale, refund, adjust, damage, transfer
  final int quantity;
  final int before;
  final int after;
  final String? referenceId; // invoiceId, supplierId, userId
  final String? note;
  final Timestamp createdAt;

  StockMovement({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.before,
    required this.after,
    this.referenceId,
    this.note,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json, String id) {
    return StockMovement(
      id: id,
      itemId: json['itemId'],
      type: json['type'],
      quantity: json['quantity'],
      before: json['before'],
      after: json['after'],
      referenceId: json['referenceId'],
      note: json['note'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'type': type,
      'quantity': quantity,
      'before': before,
      'after': after,
      'referenceId': referenceId,
      'note': note,
      'createdAt': createdAt,
    };
  }

  // Get color code for movement type
  String get typeColor {
    switch (type.toLowerCase()) {
      case 'purchase':
        return 'green'; // incoming
      case 'sale':
        return 'red'; // outgoing
      case 'refund':
        return 'orange'; // return
      case 'adjust':
        return 'blue'; // adjustment
      case 'damage':
        return 'red'; // loss
      case 'transfer':
        return 'purple'; // movement
      default:
        return 'grey';
    }
  }

  // Get icon for movement type
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'purchase':
        return '📦'; // incoming package
      case 'sale':
        return '🛍️'; // sale
      case 'refund':
        return '↩️'; // return
      case 'adjust':
        return '⚙️'; // adjustment
      case 'damage':
        return '❌'; // damaged
      case 'transfer':
        return '🔄'; // transfer
      default:
        return '📝';
    }
  }

  // Determine if this is inflow or outflow
  bool get isInflow => type.toLowerCase() == 'purchase' || type.toLowerCase() == 'refund' || type.toLowerCase() == 'adjust';
}
