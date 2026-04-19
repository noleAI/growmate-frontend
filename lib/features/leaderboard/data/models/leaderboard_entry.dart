import 'package:characters/characters.dart';

import '../../../../shared/utils/backend_text.dart';

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

  String get safeDisplayName {
    final trimmed = repairAndCollapseText(displayName);
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    final fallbackFromId = userId.trim();
    if (fallbackFromId.isNotEmpty) {
      final shortId = fallbackFromId.length > 6
          ? fallbackFromId.substring(0, 6)
          : fallbackFromId;
      return 'Người chơi $shortId';
    }

    return rank > 0 ? 'Người chơi #$rank' : 'Người chơi';
  }

  String get shortDisplayName {
    final parts = safeDisplayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return safeDisplayName;
    }
    return parts.length == 1 ? parts.first : parts.last;
  }

  String get initials {
    final parts = safeDisplayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }

    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return '$first$second'.toUpperCase();
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final parsedDisplayName =
        [
              json['display_name'],
              json['full_name'],
              json['name'],
              json['username'],
              json['email'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    return LeaderboardEntry(
      userId: (json['user_id'] ?? '').toString(),
      displayName: parsedDisplayName,
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
