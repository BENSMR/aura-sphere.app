class CRMContact {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String? notes;
  final List<String> tags;

  CRMContact({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.notes,
    this.tags = const [],
  });

  factory CRMContact.fromJson(Map<String, dynamic> json) {
    return CRMContact(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'notes': notes,
      'tags': tags,
    };
  }
}
