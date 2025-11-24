class Invoice {
  final String id;
  final String userId;
  final String clientId;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String status;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.invoiceNumber,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['userId'],
      clientId: json['clientId'],
      invoiceNumber: json['invoiceNumber'],
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'],
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: DateTime.parse(json['dueDate']),
      items: (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'currency': currency,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
