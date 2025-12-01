import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final String provider;
  final DateTime paidAt;
  final String? stripePaymentIntent;
  final String? stripeSessionId;
  final String? receiptUrl;
  final String? cardBrand;
  final String? last4;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.paidAt,
    this.stripePaymentIntent,
    this.stripeSessionId,
    this.receiptUrl,
    this.cardBrand,
    this.last4,
  });

  factory PaymentRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return PaymentRecord(
      id: id,
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'usd',
      provider: data['provider'] ?? 'stripe',
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      stripePaymentIntent: data['stripePaymentIntent'],
      stripeSessionId: data['stripeSessionId'],
      receiptUrl: data['receiptUrl'],
      cardBrand: data['cardBrand'],
      last4: data['last4'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'provider': provider,
      'paidAt': Timestamp.fromDate(paidAt),
      'stripePaymentIntent': stripePaymentIntent,
      'stripeSessionId': stripeSessionId,
      'receiptUrl': receiptUrl,
      'cardBrand': cardBrand,
      'last4': last4,
    };
  }

  PaymentRecord copyWith({
    String? id,
    double? amount,
    String? currency,
    String? provider,
    DateTime? paidAt,
    String? stripePaymentIntent,
    String? stripeSessionId,
    String? receiptUrl,
    String? cardBrand,
    String? last4,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      provider: provider ?? this.provider,
      paidAt: paidAt ?? this.paidAt,
      stripePaymentIntent: stripePaymentIntent ?? this.stripePaymentIntent,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      cardBrand: cardBrand ?? this.cardBrand,
      last4: last4 ?? this.last4,
    );
  }

  @override
  String toString() =>
      'PaymentRecord(id: $id, amount: $amount, currency: $currency, provider: $provider, paidAt: $paidAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          currency == other.currency &&
          provider == other.provider &&
          paidAt == other.paidAt;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      currency.hashCode ^
      provider.hashCode ^
      paidAt.hashCode;
}
