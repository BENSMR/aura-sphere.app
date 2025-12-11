/// AuditEntry model for Flutter
/// 
/// Represents immutable audit trail entries for compliance and debugging
/// Firestore Path: /audit/{compositeId}/entries/{entryId}

class AuditActor {
  final String uid;
  final String? name;
  final String? email;
  final String? role;

  AuditActor({
    required this.uid,
    this.name,
    this.email,
    this.role,
  });

  factory AuditActor.fromJson(Map<String, dynamic> json) {
    return AuditActor(
      uid: json['uid'] as String? ?? 'unknown',
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
      };
}

class AuditMetadata {
  final String? requestId;
  final FxSnapshot? fxSnapshot;
  final TaxBreakdown? taxBreakdown;
  final String? reason;
  final Map<String, dynamic>? extra;

  AuditMetadata({
    this.requestId,
    this.fxSnapshot,
    this.taxBreakdown,
    this.reason,
    this.extra,
  });

  factory AuditMetadata.fromJson(Map<String, dynamic> json) {
    return AuditMetadata(
      requestId: json['requestId'] as String?,
      fxSnapshot: json['fxSnapshot'] != null
          ? FxSnapshot.fromJson(json['fxSnapshot'] as Map<String, dynamic>)
          : null,
      taxBreakdown: json['taxBreakdown'] != null
          ? TaxBreakdown.fromJson(json['taxBreakdown'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String?,
      extra: {...?json}..removeWhere((k, v) => ['requestId', 'fxSnapshot', 'taxBreakdown', 'reason'].contains(k)),
    );
  }

  Map<String, dynamic> toJson() => {
        if (requestId != null) 'requestId': requestId,
        if (fxSnapshot != null) 'fxSnapshot': fxSnapshot!.toJson(),
        if (taxBreakdown != null) 'taxBreakdown': taxBreakdown!.toJson(),
        if (reason != null) 'reason': reason,
        ...?extra,
      };
}

class FxSnapshot {
  final String base;
  final Map<String, double> rates;
  final String? provider;
  final DateTime? updatedAt;

  FxSnapshot({
    required this.base,
    required this.rates,
    this.provider,
    this.updatedAt,
  });

  factory FxSnapshot.fromJson(Map<String, dynamic> json) {
    return FxSnapshot(
      base: json['base'] as String? ?? 'USD',
      rates: Map<String, double>.from(
        (json['rates'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      provider: json['provider'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'rates': rates,
        if (provider != null) 'provider': provider,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

class TaxBreakdown {
  final String type; // 'vat', 'sales_tax', 'none'
  final double rate;
  final double? amount;
  final String? country;

  TaxBreakdown({
    required this.type,
    required this.rate,
    this.amount,
    this.country,
  });

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      type: json['type'] as String? ?? 'none',
      rate: (json['rate'] as num? ?? 0).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'rate': rate,
        if (amount != null) 'amount': amount,
        if (country != null) 'country': country,
      };
}

class AuditEntry {
  final String entryId; // Firestore doc ID
  final AuditActor actor;
  final String action;
  final String entityType;
  final String entityId;
  final DateTime timestamp;
  final String source;
  final String? ip;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final AuditMetadata? meta;
  final List<String> tags;
  final bool immutable;

  AuditEntry({
    required this.entryId,
    required this.actor,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    required this.source,
    this.ip,
    this.before,
    this.after,
    this.meta,
    required this.tags,
    required this.immutable,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json, [String? docId]) {
    return AuditEntry(
      entryId: docId ?? json['entryId'] as String? ?? 'unknown',
      actor: AuditActor.fromJson(json['actor'] as Map<String, dynamic>? ?? {}),
      action: json['action'] as String? ?? 'unknown',
      entityType: json['entityType'] as String? ?? 'unknown',
      entityId: json['entityId'] as String? ?? 'unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      source: json['source'] as String? ?? 'unknown',
      ip: json['ip'] as String?,
      before: json['before'] as Map<String, dynamic>?,
      after: json['after'] as Map<String, dynamic>?,
      meta: json['meta'] != null
          ? AuditMetadata.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      immutable: json['immutable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'actor': actor.toJson(),
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        if (ip != null) 'ip': ip,
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        if (meta != null) 'meta': meta!.toJson(),
        'tags': tags,
        'immutable': immutable,
      };

  /// Human-readable description
  String get description {
    return '${actor.name ?? actor.uid} · $action · $timestamp';
  }

  /// Check if this is a tax-related audit entry
  bool get isTaxRelated => tags.contains('tax');

  /// Check if this is a critical audit entry
  bool get isCritical => tags.contains('critical');
}

/// Denormalized audit index for fast lookups
/// Path: /audit_index/{compositeId}
/// 
/// Purpose: Provides quick access to latest audit entry info without
/// querying the full audit trail, ideal for UI displays
class AuditIndexEntry {
  final String compositeId;
  final String entityType;
  final String entityId;
  final String latestEntryId;
  final DateTime latestAt;
  final String latestAction;
  final String latestActorUid;
  final String? latestActorName;
  final List<String> tags;
  final int? entryCount;

  AuditIndexEntry({
    required this.compositeId,
    required this.entityType,
    required this.entityId,
    required this.latestEntryId,
    required this.latestAt,
    required this.latestAction,
    required this.latestActorUid,
    this.latestActorName,
    required this.tags,
    this.entryCount,
  });

  factory AuditIndexEntry.fromJson(Map<String, dynamic> json) {
    return AuditIndexEntry(
      compositeId: json['compositeId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'unknown',
      entityId: json['entityId'] as String? ?? 'unknown',
      latestEntryId: json['latestEntryId'] as String? ?? '',
      latestAt: json['latestAt'] != null
          ? DateTime.parse(json['latestAt'].toString())
          : DateTime.now(),
      latestAction: json['latestAction'] as String? ?? 'unknown',
      latestActorUid: json['latestActorUid'] as String? ?? 'unknown',
      latestActorName: json['latestActorName'] as String?,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      entryCount: json['entryCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'compositeId': compositeId,
        'entityType': entityType,
        'entityId': entityId,
        'latestEntryId': latestEntryId,
        'latestAt': latestAt.toIso8601String(),
        'latestAction': latestAction,
        'latestActorUid': latestActorUid,
        if (latestActorName != null) 'latestActorName': latestActorName,
        'tags': tags,
        if (entryCount != null) 'entryCount': entryCount,
      };

  /// Human-readable summary of latest action
  String get summary {
    final actor = latestActorName ?? latestActorUid;
    return '$actor · $latestAction · ${latestAt.toString().split('.')[0]}';
  }

  /// Check if index contains tax-related entries
  bool get hasTaxEntries => tags.contains('tax');

  /// Check if index contains critical entries
  bool get hasCriticalEntries => tags.contains('critical');
}
