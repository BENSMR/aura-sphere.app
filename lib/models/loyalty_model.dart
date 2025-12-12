class LoyaltyStreak {
  final int current;
  final DateTime lastLogin;
  final DateTime? frozenUntil;

  LoyaltyStreak({
    required this.current,
    required this.lastLogin,
    this.frozenUntil,
  });

  factory LoyaltyStreak.fromJson(Map<String, dynamic> json) {
    return LoyaltyStreak(
      current: json['current'] as int? ?? 0,
      lastLogin: json['lastLogin'] is DateTime
          ? json['lastLogin'] as DateTime
          : DateTime.parse(json['lastLogin'] as String? ?? DateTime.now().toIso8601String()),
      frozenUntil: json['frozenUntil'] != null
          ? (json['frozenUntil'] is DateTime
              ? json['frozenUntil'] as DateTime
              : DateTime.parse(json['frozenUntil'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'lastLogin': lastLogin,
        'frozenUntil': frozenUntil,
      };
}

class LoyaltyTotals {
  final int lifetimeEarned;
  final int lifetimeSpent;

  LoyaltyTotals({
    required this.lifetimeEarned,
    required this.lifetimeSpent,
  });

  factory LoyaltyTotals.fromJson(Map<String, dynamic> json) {
    return LoyaltyTotals(
      lifetimeEarned: json['lifetimeEarned'] as int? ?? 0,
      lifetimeSpent: json['lifetimeSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'lifetimeEarned': lifetimeEarned,
        'lifetimeSpent': lifetimeSpent,
      };
}

class LoyaltyBadge {
  final String id;
  final String name;
  final int level;
  final DateTime earnedAt;

  LoyaltyBadge({
    required this.id,
    required this.name,
    required this.level,
    required this.earnedAt,
  });

  factory LoyaltyBadge.fromJson(Map<String, dynamic> json) {
    return LoyaltyBadge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      earnedAt: json['earnedAt'] is DateTime
          ? json['earnedAt'] as DateTime
          : DateTime.parse(json['earnedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'earnedAt': earnedAt,
      };
}

class LoyaltyMilestones {
  final bool bronze;
  final bool silver;
  final bool gold;
  final bool platinum;
  final bool diamond;

  LoyaltyMilestones({
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.platinum,
    required this.diamond,
  });

  factory LoyaltyMilestones.fromJson(Map<String, dynamic> json) {
    return LoyaltyMilestones(
      bronze: json['bronze'] as bool? ?? false,
      silver: json['silver'] as bool? ?? false,
      gold: json['gold'] as bool? ?? false,
      platinum: json['platinum'] as bool? ?? false,
      diamond: json['diamond'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'bronze': bronze,
        'silver': silver,
        'gold': gold,
        'platinum': platinum,
        'diamond': diamond,
      };
}

class UserLoyalty {
  final String uid;
  final LoyaltyStreak streak;
  final LoyaltyTotals totals;
  final List<LoyaltyBadge> badges;
  final LoyaltyMilestones milestones;
  final DateTime? lastBonus;

  UserLoyalty({
    required this.uid,
    required this.streak,
    required this.totals,
    required this.badges,
    required this.milestones,
    this.lastBonus,
  });

  factory UserLoyalty.fromJson(String uid, Map<String, dynamic> json) {
    return UserLoyalty(
      uid: uid,
      streak: LoyaltyStreak.fromJson(json['streak'] as Map<String, dynamic>? ?? {}),
      totals: LoyaltyTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => LoyaltyBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: LoyaltyMilestones.fromJson(json['milestones'] as Map<String, dynamic>? ?? {}),
      lastBonus: json['lastBonus'] != null
          ? (json['lastBonus'] is DateTime
              ? json['lastBonus'] as DateTime
              : DateTime.parse(json['lastBonus'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'streak': streak.toJson(),
        'totals': totals.toJson(),
        'badges': badges.map((e) => e.toJson()).toList(),
        'milestones': milestones.toJson(),
        'lastBonus': lastBonus,
      };
}
