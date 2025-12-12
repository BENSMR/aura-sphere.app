import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single timeline event for a client (invoice, payment, interaction)
class TimelineEvent {
  final String type; // "invoice_created", "invoice_paid", "payment_received", "interaction"
  final String message;
  final double amount;
  final DateTime createdAt;

  TimelineEvent({
    required this.type,
    required this.message,
    required this.amount,
    required this.createdAt,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      type: map['type'] ?? '',
      message: map['message'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ClientModel {
  final String id;
  final String userId;
  
  // Basic information
  final String name;
  final String email;
  final String phone;
  final String company;
  final String address;
  final String country;
  final String notes;
  
  // AI intelligence
  final int aiScore; // 0–100 relationship score
  final List<String> aiTags; // "VIP", "unstable", "high value"
  final String aiSummary; // auto-generated summary
  final String sentiment; // "positive", "neutral", "negative"
  
  // Value metrics
  final double lifetimeValue; // total paid invoices
  final int totalInvoices;
  final double lastInvoiceAmount;
  
  // Status and tags
  final List<String> tags;
  final String status; // lead | active | vip | lost
  
  // Engagement
  final DateTime? lastActivityAt;
  final DateTime? lastInvoiceDate;
  final DateTime? lastPaymentDate;
  
  // AI-generated insights
  final int churnRisk; // 0–100
  final bool vipStatus;
  final String stabilityLevel; // "unknown", "stable", "unstable", "risky"
  
  // Timeline for history
  final List<TimelineEvent> timeline;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.address = '',
    this.country = '',
    required this.notes,
    this.aiScore = 0,
    this.aiTags = const [],
    this.aiSummary = '',
    this.sentiment = 'neutral',
    this.lifetimeValue = 0,
    this.totalInvoices = 0,
    this.lastInvoiceAmount = 0,
    required this.tags,
    required this.status,
    required this.lastActivityAt,
    this.lastInvoiceDate,
    this.lastPaymentDate,
    this.churnRisk = 0,
    this.vipStatus = false,
    this.stabilityLevel = 'unknown',
    this.timeline = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timelineData = data['timeline'] as Map<String, dynamic>? ?? {};
    final events = timelineData['events'] as List<dynamic>? ?? [];
    
    return ClientModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      company: data['company'] ?? '',
      address: data['address'] ?? '',
      country: data['country'] ?? '',
      notes: data['notes'] ?? '',
      aiScore: (data['aiScore'] ?? 0) as int,
      aiTags: List<String>.from(data['aiTags'] ?? const []),
      aiSummary: data['aiSummary'] ?? '',
      sentiment: data['sentiment'] ?? 'neutral',
      lifetimeValue: (data['lifetimeValue'] ?? 0).toDouble(),
      totalInvoices: (data['totalInvoices'] ?? 0) as int,
      lastInvoiceAmount: (data['lastInvoiceAmount'] ?? 0).toDouble(),
      tags: List<String>.from(data['tags'] ?? const []),
      status: data['status'] ?? 'lead',
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
      lastInvoiceDate: (data['lastInvoiceDate'] as Timestamp?)?.toDate(),
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp?)?.toDate(),
      churnRisk: (data['churnRisk'] ?? 0) as int,
      vipStatus: data['vipStatus'] ?? false,
      stabilityLevel: data['stabilityLevel'] ?? 'unknown',
      timeline: events
          .map((e) => TimelineEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'address': address,
      'country': country,
      'notes': notes,
      'aiScore': aiScore,
      'aiTags': aiTags,
      'aiSummary': aiSummary,
      'sentiment': sentiment,
      'lifetimeValue': lifetimeValue,
      'totalInvoices': totalInvoices,
      'lastInvoiceAmount': lastInvoiceAmount,
      'tags': tags,
      'status': status,
      'lastActivityAt': lastActivityAt != null
          ? Timestamp.fromDate(lastActivityAt!)
          : null,
      'lastInvoiceDate': lastInvoiceDate != null
          ? Timestamp.fromDate(lastInvoiceDate!)
          : null,
      'lastPaymentDate': lastPaymentDate != null
          ? Timestamp.fromDate(lastPaymentDate!)
          : null,
      'churnRisk': churnRisk,
      'vipStatus': vipStatus,
      'stabilityLevel': stabilityLevel,
      'timeline': {
        'events': timeline.map((e) => e.toMap()).toList(),
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ClientModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? company,
    String? address,
    String? country,
    String? notes,
    int? aiScore,
    List<String>? aiTags,
    String? aiSummary,
    String? sentiment,
    double? lifetimeValue,
    int? totalInvoices,
    double? lastInvoiceAmount,
    List<String>? tags,
    String? status,
    DateTime? lastActivityAt,
    DateTime? lastInvoiceDate,
    DateTime? lastPaymentDate,
    int? churnRisk,
    bool? vipStatus,
    String? stabilityLevel,
    List<TimelineEvent>? timeline,
  }) {
    return ClientModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      address: address ?? this.address,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      aiScore: aiScore ?? this.aiScore,
      aiTags: aiTags ?? this.aiTags,
      aiSummary: aiSummary ?? this.aiSummary,
      sentiment: sentiment ?? this.sentiment,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      lastInvoiceAmount: lastInvoiceAmount ?? this.lastInvoiceAmount,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      churnRisk: churnRisk ?? this.churnRisk,
      vipStatus: vipStatus ?? this.vipStatus,
      stabilityLevel: stabilityLevel ?? this.stabilityLevel,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for API responses
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'address': address,
      'country': country,
      'notes': notes,
      'aiScore': aiScore,
      'aiTags': aiTags,
      'aiSummary': aiSummary,
      'sentiment': sentiment,
      'lifetimeValue': lifetimeValue,
      'totalInvoices': totalInvoices,
      'lastInvoiceAmount': lastInvoiceAmount,
      'tags': tags,
      'status': status,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'lastInvoiceDate': lastInvoiceDate?.toIso8601String(),
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'churnRisk': churnRisk,
      'vipStatus': vipStatus,
      'stabilityLevel': stabilityLevel,
      'timeline': {
        'events': timeline.map((e) => e.toJson()).toList(),
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final timelineData = json['timeline'] as Map<String, dynamic>? ?? {};
    final events = timelineData['events'] as List<dynamic>? ?? [];
    
    return ClientModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      address: json['address'] as String? ?? '',
      country: json['country'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      aiScore: (json['aiScore'] ?? 0) as int,
      aiTags: List<String>.from(json['aiTags'] ?? []),
      aiSummary: json['aiSummary'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      lifetimeValue: (json['lifetimeValue'] ?? 0).toDouble(),
      totalInvoices: (json['totalInvoices'] ?? 0) as int,
      lastInvoiceAmount: (json['lastInvoiceAmount'] ?? 0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      status: json['status'] as String? ?? 'lead',
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      lastInvoiceDate: json['lastInvoiceDate'] != null
          ? DateTime.parse(json['lastInvoiceDate'] as String)
          : null,
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'] as String)
          : null,
      churnRisk: (json['churnRisk'] ?? 0) as int,
      vipStatus: json['vipStatus'] ?? false,
      stabilityLevel: json['stabilityLevel'] as String? ?? 'unknown',
      timeline: events
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Add note to client
  ClientModel addNote(String newNote) {
    final updated = notes.isEmpty ? newNote : '$notes\n$newNote';
    return copyWith(notes: updated);
  }

  /// Update status
  ClientModel updateStatus(String newStatus) {
    assert(['lead', 'active', 'vip', 'lost'].contains(newStatus), 'Invalid status');
    return copyWith(status: newStatus);
  }

  /// Add tag
  ClientModel addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// Remove tag
  ClientModel removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// Record activity
  ClientModel recordActivity() {
    return copyWith(lastActivityAt: DateTime.now());
  }

  /// Add timeline event
  ClientModel addTimelineEvent(TimelineEvent event) {
    return copyWith(timeline: [...timeline, event]);
  }

  /// Update AI score
  ClientModel updateAiScore(int newScore) {
    assert(newScore >= 0 && newScore <= 100, 'Score must be 0-100');
    return copyWith(aiScore: newScore);
  }

  /// Update churn risk
  ClientModel updateChurnRisk(int risk) {
    assert(risk >= 0 && risk <= 100, 'Risk must be 0-100');
    return copyWith(churnRisk: risk);
  }

  /// Update lifetime value (cumulative)
  ClientModel addLifetimeValue(double amount) {
    return copyWith(lifetimeValue: lifetimeValue + amount);
  }

  /// Record invoice payment
  ClientModel recordInvoicePayment(double amount, DateTime paymentDate) {
    return copyWith(
      lastPaymentDate: paymentDate,
      lifetimeValue: lifetimeValue + amount,
      lastActivityAt: paymentDate,
    );
  }

  /// Record invoice creation
  ClientModel recordInvoiceCreation(double amount, DateTime invoiceDate) {
    return copyWith(
      lastInvoiceDate: invoiceDate,
      lastInvoiceAmount: amount,
      totalInvoices: totalInvoices + 1,
      lastActivityAt: invoiceDate,
    );
  }

  /// Update AI-generated summary
  ClientModel updateAiSummary({
    String? summary,
    String? sentiment,
    List<String>? aiTags,
  }) {
    return copyWith(
      aiSummary: summary,
      sentiment: sentiment,
      aiTags: aiTags,
    );
  }

  /// Update stability level
  ClientModel updateStabilityLevel(String level) {
    assert(['unknown', 'stable', 'unstable', 'risky'].contains(level),
        'Invalid stability level');
    return copyWith(stabilityLevel: level);
  }

  /// Toggle VIP status
  ClientModel toggleVipStatus() {
    return copyWith(vipStatus: !vipStatus);
  }

  /// Total value getter (alias for lifetime value)
  double get totalValue => lifetimeValue;
}
