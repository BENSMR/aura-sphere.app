class Project {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final double? budget;
  final List<String> teamMembers;

  Project({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    this.endDate,
    this.budget,
    this.teamMembers = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      budget: json['budget']?.toDouble(),
      teamMembers: List<String>.from(json['teamMembers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'teamMembers': teamMembers,
    };
  }
}
