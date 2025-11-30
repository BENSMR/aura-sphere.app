// lib/models/invoice_item.dart
class InvoiceItem {
  String name;
  String description;
  int quantity;
  double unitPrice;
  double vatRate;

  InvoiceItem({
    required this.name,
    this.description = '',
    this.quantity = 1,
    required this.unitPrice,
    this.vatRate = 0.0,
  });

  double get total => quantity * unitPrice * (1 + vatRate / 100);

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'vatRate': vatRate,
        'total': total,
      };

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'vatRate': vatRate,
      };

  static InvoiceItem fromMap(Map<String, dynamic> m) => InvoiceItem(
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        quantity: (m['quantity'] ?? 1),
        unitPrice: (m['unitPrice'] ?? 0).toDouble(),
        vatRate: (m['vatRate'] ?? 0).toDouble(),
      );

  static InvoiceItem fromJson(Map<String, dynamic> json) => InvoiceItem(
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        quantity: (json['quantity'] ?? 1),
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        vatRate: (json['vatRate'] ?? 0).toDouble(),
      );
}
