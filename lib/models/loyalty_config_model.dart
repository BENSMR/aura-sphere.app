class DailyConfig {
  final int baseReward;
  final int streakBonus;
  final int maxStreakBonus;

  DailyConfig({
    required this.baseReward,
    required this.streakBonus,
    required this.maxStreakBonus,
  });

  factory DailyConfig.fromJson(Map<String, dynamic> json) {
    return DailyConfig(
      baseReward: json['baseReward'] as int? ?? 50,
      streakBonus: json['streakBonus'] as int? ?? 10,
      maxStreakBonus: json['maxStreakBonus'] as int? ?? 500,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseReward': baseReward,
        'streakBonus': streakBonus,
        'maxStreakBonus': maxStreakBonus,
      };
}

class WeeklyConfig {
  final int thresholdDays;
  final int bonus;

  WeeklyConfig({
    required this.thresholdDays,
    required this.bonus,
  });

  factory WeeklyConfig.fromJson(Map<String, dynamic> json) {
    return WeeklyConfig(
      thresholdDays: json['thresholdDays'] as int? ?? 7,
      bonus: json['bonus'] as int? ?? 500,
    );
  }

  Map<String, dynamic> toJson() => {
        'thresholdDays': thresholdDays,
        'bonus': bonus,
      };
}

class MilestoneItem {
  final String id;
  final String name;
  final int tokensThreshold;
  final int reward;

  MilestoneItem({
    required this.id,
    required this.name,
    required this.tokensThreshold,
    required this.reward,
  });

  factory MilestoneItem.fromJson(Map<String, dynamic> json) {
    return MilestoneItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tokensThreshold: json['tokensThreshold'] as int? ?? 0,
      reward: json['reward'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tokensThreshold': tokensThreshold,
        'reward': reward,
      };
}

class SpecialDay {
  final String dateISO;
  final double bonusMultiplier;
  final String name;

  SpecialDay({
    required this.dateISO,
    required this.bonusMultiplier,
    required this.name,
  });

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(
      dateISO: json['dateISO'] as String? ?? '',
      bonusMultiplier: (json['bonusMultiplier'] as num? ?? 1.0).toDouble(),
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'dateISO': dateISO,
        'bonusMultiplier': bonusMultiplier,
        'name': name,
      };
}

class LoyaltyConfig {
  final DailyConfig daily;
  final WeeklyConfig weekly;
  final List<MilestoneItem> milestones;
  final List<SpecialDay> specialDays;

  LoyaltyConfig({
    required this.daily,
    required this.weekly,
    required this.milestones,
    required this.specialDays,
  });

  factory LoyaltyConfig.fromJson(Map<String, dynamic> json) {
    return LoyaltyConfig(
      daily: DailyConfig.fromJson(json['daily'] as Map<String, dynamic>? ?? {}),
      weekly: WeeklyConfig.fromJson(json['weekly'] as Map<String, dynamic>? ?? {}),
      milestones: (json['milestones'] as List<dynamic>? ?? [])
          .map((e) => MilestoneItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialDays: (json['specialDays'] as List<dynamic>? ?? [])
          .map((e) => SpecialDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'daily': daily.toJson(),
        'weekly': weekly.toJson(),
        'milestones': milestones.map((e) => e.toJson()).toList(),
        'specialDays': specialDays.map((e) => e.toJson()).toList(),
      };
}
