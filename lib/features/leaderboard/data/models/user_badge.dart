/// Badge mà user có thể đạt được trong hệ thống gamification.
class UserBadge {
  const UserBadge({
    required this.id,
    required this.badgeType,
    required this.badgeName,
    required this.iconEmoji,
    this.earnedAt,
    required this.description,
    this.unlockCondition,
  });

  final String id;

  /// Ví dụ: 'streak_7', 'top_10', 'mastery_chain_rule'
  final String badgeType;

  /// Ví dụ: 'Chiến thần Đạo hàm'
  final String badgeName;

  /// Ví dụ: '🏆'
  final String iconEmoji;

  /// null = chưa unlock
  final DateTime? earnedAt;

  final String description;

  /// Điều kiện để mở khóa badge (cho UI)
  final String? unlockCondition;

  /// Badge đã được unlock chưa
  bool get isUnlocked => earnedAt != null;

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      badgeType: json['badge_type'] as String,
      badgeName: json['badge_name'] as String,
      iconEmoji: json['icon_emoji'] as String,
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'] as String)
          : null,
      description: json['description'] as String,
      unlockCondition: json['unlock_condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'badge_type': badgeType,
    'badge_name': badgeName,
    'icon_emoji': iconEmoji,
    'earned_at': earnedAt?.toIso8601String(),
    'description': description,
    'unlock_condition': unlockCondition,
  };
}
