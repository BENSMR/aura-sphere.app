class BusinessModel {
  final String id;
  final String name;
  final String? industry;
  final String? address;
  final String? phone;
  final String ownerId;

  BusinessModel({
    required this.id,
    required this.name,
    this.industry,
    this.address,
    this.phone,
    required this.ownerId,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],
      name: json['name'],
      industry: json['industry'],
      address: json['address'],
      phone: json['phone'],
      ownerId: json['ownerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'industry': industry,
      'address': address,
      'phone': phone,
      'ownerId': ownerId,
    };
  }
}
