class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? businessId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.businessId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      businessId: json['businessId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'businessId': businessId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
