class PaymentProcessed {
  final String sessionId;
  final String uid;
  final String packId;
  final int tokens;
  final DateTime processedAt;

  PaymentProcessed({
    required this.sessionId,
    required this.uid,
    required this.packId,
    required this.tokens,
    required this.processedAt,
  });

  factory PaymentProcessed.fromJson(String sessionId, Map<String, dynamic> json) {
    return PaymentProcessed(
      sessionId: sessionId,
      uid: json['uid'] as String? ?? '',
      packId: json['packId'] as String? ?? '',
      tokens: json['tokens'] as int? ?? 0,
      processedAt: json['processedAt'] is DateTime
          ? json['processedAt'] as DateTime
          : DateTime.parse(json['processedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'packId': packId,
        'tokens': tokens,
        'processedAt': processedAt,
      };
}

class TokenAuditEntry {
  final String txId;
  final String uid;
  final String action;
  final int amount;
  final String? sessionId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  TokenAuditEntry({
    required this.txId,
    required this.uid,
    required this.action,
    required this.amount,
    this.sessionId,
    required this.createdAt,
    this.metadata,
  });

  factory TokenAuditEntry.fromJson(String txId, String uid, Map<String, dynamic> json) {
    return TokenAuditEntry(
      txId: txId,
      uid: uid,
      action: json['action'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      sessionId: json['sessionId'] as String?,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'amount': amount,
        'sessionId': sessionId,
        'createdAt': createdAt,
        'metadata': metadata,
      };
}
