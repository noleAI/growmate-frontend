/// Một entry trên bảng xếp hạng.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.rank,
    this.xp,
    required this.weeklyXp,
    required this.totalXp,
    required this.currentStreak,
    this.badgeCount = 0,
    this.longestStreak = 0,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int rank;
  final int? xp;
  final int weeklyXp;
  final int totalXp;
  final int currentStreak;
  final int badgeCount;
  final int longestStreak;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      rank: _toInt(json['rank']) ?? 0,
      xp: _toInt(json['xp']),
      weeklyXp: _toInt(json['weekly_xp']) ?? _toInt(json['xp']) ?? 0,
      totalXp: _toInt(json['total_xp']) ?? 0,
      currentStreak:
          _toInt(json['current_streak']) ?? _toInt(json['streak']) ?? 0,
      badgeCount: _toInt(json['badge_count']) ?? 0,
      longestStreak: _toInt(json['longest_streak']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'rank': rank,
    'xp': xp,
    'weekly_xp': weeklyXp,
    'total_xp': totalXp,
    'current_streak': currentStreak,
    'badge_count': badgeCount,
    'longest_streak': longestStreak,
  };

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? rank,
    int? xp,
    int? weeklyXp,
    int? totalXp,
    int? currentStreak,
    int? badgeCount,
    int? longestStreak,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      xp: xp ?? this.xp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      badgeCount: badgeCount ?? this.badgeCount,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}

int? _toInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}
