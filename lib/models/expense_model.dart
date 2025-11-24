class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final String description;
  final DateTime date;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    required this.description,
    required this.date,
    this.receiptUrl,
    this.metadata,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      receiptUrl: json['receiptUrl'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }
}
