class Project {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final double budget;
  final String userId;
  final List<String> teamMembers;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.budget,
    required this.userId,
    required this.teamMembers,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      budget: (json['budget'] as num).toDouble(),
      userId: json['userId'] as String,
      teamMembers: List<String>.from(json['teamMembers'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'userId': userId,
      'teamMembers': teamMembers,
    };
  }
}