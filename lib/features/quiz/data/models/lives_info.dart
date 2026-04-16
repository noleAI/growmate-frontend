/// Thông tin hệ thống tim (lives) của user.
class LivesInfo {
  const LivesInfo({
    required this.currentLives,
    required this.maxLives,
    this.lastLifeLostAt,
    this.nextRegenIn,
  });

  /// Số tim hiện tại (0-3)
  final int currentLives;

  /// Số tim tối đa
  final int maxLives;

  final DateTime? lastLifeLostAt;

  /// Thời gian đến lần hồi sinh tiếp theo; null nếu đầy tim
  final Duration? nextRegenIn;

  bool get isFull => currentLives >= maxLives;
  bool get isEmpty => currentLives <= 0;
  bool get canPlay => currentLives > 0;

  LivesInfo copyWith({
    int? currentLives,
    int? maxLives,
    DateTime? lastLifeLostAt,
    Duration? nextRegenIn,
  }) {
    return LivesInfo(
      currentLives: currentLives ?? this.currentLives,
      maxLives: maxLives ?? this.maxLives,
      lastLifeLostAt: lastLifeLostAt ?? this.lastLifeLostAt,
      nextRegenIn: nextRegenIn ?? this.nextRegenIn,
    );
  }

  factory LivesInfo.fromJson(Map<String, dynamic> json) {
    // Support both frontend keys (current_lives) and backend keys (current).
    final currentLives =
        (json['current_lives'] ?? json['current'] ?? json['remaining'])
            as int? ??
        3;
    final maxLives = (json['max_lives'] ?? json['max']) as int? ?? 3;
    final nextRegenSec = json['next_regen_in_seconds'] as int?;
    return LivesInfo(
      currentLives: currentLives,
      maxLives: maxLives,
      lastLifeLostAt: json['last_life_lost_at'] != null
          ? DateTime.tryParse(json['last_life_lost_at'].toString())
          : null,
      nextRegenIn: nextRegenSec != null
          ? Duration(seconds: nextRegenSec)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'current_lives': currentLives,
    'max_lives': maxLives,
    'last_life_lost_at': lastLifeLostAt?.toIso8601String(),
  };
}
