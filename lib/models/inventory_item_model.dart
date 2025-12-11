import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? imageUrl;
  final String? category;
  final String? brand;
  final String? supplierId;
  final String? supplierName;

  final double costPrice;
  final double sellingPrice;
  final double tax;

  final int stockQuantity;
  final int minimumStock;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.imageUrl,
    this.category,
    this.brand,
    this.supplierId,
    this.supplierName,
    required this.costPrice,
    required this.sellingPrice,
    required this.tax,
    required this.stockQuantity,
    required this.minimumStock,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔄 Create empty item (for UI)
  factory InventoryItem.empty() {
    return InventoryItem(
      id: '',
      name: '',
      sku: '',
      costPrice: 0,
      sellingPrice: 0,
      tax: 0,
      stockQuantity: 0,
      minimumStock: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  // 🔥 Firestore → Model
  factory InventoryItem.fromJson(Map<String, dynamic> json, String id) {
    return InventoryItem(
      id: id,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      brand: json['brand'],
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      minimumStock: json['minimumStock'] ?? 0,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'tax': tax,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Clone with modifications
  InventoryItem copyWith({
    String? name,
    String? sku,
    String? barcode,
    String? imageUrl,
    String? category,
    String? brand,
    String? supplierId,
    String? supplierName,
    double? costPrice,
    double? sellingPrice,
    double? tax,
    int? stockQuantity,
    int? minimumStock,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      tax: tax ?? this.tax,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
    );
  }

  // Calculate profit per unit
  double get profitPerUnit => sellingPrice - costPrice;

  // Calculate profit margin percentage
  double get profitMargin => (profitPerUnit / sellingPrice * 100).toStringAsFixed(2) == 'NaN' ? 0 : (profitPerUnit / sellingPrice * 100);

  // Check if low stock
  bool get isLowStock => stockQuantity <= minimumStock;

  // Calculate stock value
  double get stockValue => costPrice * stockQuantity;
}
