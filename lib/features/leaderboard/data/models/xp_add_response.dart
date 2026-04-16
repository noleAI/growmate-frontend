/// Response model for POST /api/v1/xp/add.
class XpAddResponse {
  const XpAddResponse({
    required this.xpAdded,
    required this.weeklyXp,
    required this.totalXp,
    required this.currentStreak,
    required this.newBadges,
    this.breakdown,
  });

  final int xpAdded;
  final int weeklyXp;
  final int totalXp;
  final int currentStreak;
  final List<NewBadge> newBadges;
  final XpBreakdown? breakdown;

  factory XpAddResponse.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['new_badges'];
    final badges = <NewBadge>[];
    if (rawBadges is List) {
      for (final item in rawBadges) {
        if (item is Map) {
          badges.add(NewBadge.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return XpAddResponse(
      xpAdded: (json['xp_added'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] as num?)?.toInt() ?? 0,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      newBadges: badges,
      breakdown: json['breakdown'] is Map
          ? XpBreakdown.fromJson(
              Map<String, dynamic>.from(json['breakdown'] as Map),
            )
          : null,
    );
  }
}

/// XP breakdown from backend: base_xp + streak_bonus + speed_bonus.
class XpBreakdown {
  const XpBreakdown({
    required this.baseXp,
    required this.streakBonus,
    required this.speedBonus,
  });

  final int baseXp;
  final int streakBonus;
  final int speedBonus;

  factory XpBreakdown.fromJson(Map<String, dynamic> json) {
    return XpBreakdown(
      baseXp: (json['base_xp'] as num?)?.toInt() ?? 0,
      streakBonus: (json['streak_bonus'] as num?)?.toInt() ?? 0,
      speedBonus: (json['speed_bonus'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A badge earned as part of an XP event.
class NewBadge {
  const NewBadge({
    required this.badgeType,
    required this.badgeName,
    required this.description,
    required this.icon,
    this.earnedAt,
  });

  final String badgeType;
  final String badgeName;
  final String description;
  final String icon;
  final DateTime? earnedAt;

  factory NewBadge.fromJson(Map<String, dynamic> json) {
    return NewBadge(
      badgeType: (json['badge_type'] ?? '').toString(),
      badgeName: (json['badge_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '🏅').toString(),
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'].toString())
          : null,
    );
  }
}
