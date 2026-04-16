/// Một entry trên bảng xếp hạng.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.rank,
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
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] ?? json['xp'] ?? 0 as num).toInt(),
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] ?? json['streak'] ?? 0 as num)
          .toInt(),
      badgeCount: (json['badge_count'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'rank': rank,
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
      weeklyXp: weeklyXp ?? this.weeklyXp,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      badgeCount: badgeCount ?? this.badgeCount,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}
