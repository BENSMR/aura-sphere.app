class CryptoWallet {
  final String id;
  final String userId;
  final String address;
  final double balance;
  final String currency;

  CryptoWallet({
    required this.id,
    required this.userId,
    required this.address,
    required this.balance,
    required this.currency,
  });

  factory CryptoWallet.fromJson(Map<String, dynamic> json) {
    return CryptoWallet(
      id: json['id'],
      userId: json['userId'],
      address: json['address'],
      balance: json['balance'].toDouble(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'address': address,
      'balance': balance,
      'currency': currency,
    };
  }
}
