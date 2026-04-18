/// Thông tin hệ thống tim (lives) của user.
class LivesInfo {
  const LivesInfo({
    required this.currentLives,
    required this.maxLives,
    this.lastLifeLostAt,
    this.nextRegenIn,
    this.nextRegenAt,
    this.serverCanPlay,
  });

  /// Số tim hiện tại (0-3)
  final int currentLives;

  /// Số tim tối đa
  final int maxLives;

  final DateTime? lastLifeLostAt;

  /// Thời gian đến lần hồi sinh tiếp theo; null nếu đầy tim
  final Duration? nextRegenIn;

  /// Mốc thời gian hồi tim tiếp theo từ backend (nếu có)
  final DateTime? nextRegenAt;

  /// Ưu tiên dùng can_play từ backend khi có.
  final bool? serverCanPlay;

  bool get isFull => currentLives >= maxLives;
  bool get isEmpty => currentLives <= 0;
  bool get canPlay => serverCanPlay ?? currentLives > 0;

  LivesInfo copyWith({
    int? currentLives,
    int? maxLives,
    DateTime? lastLifeLostAt,
    Duration? nextRegenIn,
    DateTime? nextRegenAt,
    bool? serverCanPlay,
  }) {
    return LivesInfo(
      currentLives: currentLives ?? this.currentLives,
      maxLives: maxLives ?? this.maxLives,
      lastLifeLostAt: lastLifeLostAt ?? this.lastLifeLostAt,
      nextRegenIn: nextRegenIn ?? this.nextRegenIn,
      nextRegenAt: nextRegenAt ?? this.nextRegenAt,
      serverCanPlay: serverCanPlay ?? this.serverCanPlay,
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
    final canPlay = _parseNullableBool(json['can_play']);
    final nextRegenAt = json['next_regen_at'] != null
        ? DateTime.tryParse(json['next_regen_at'].toString())
        : null;
    return LivesInfo(
      currentLives: currentLives,
      maxLives: maxLives,
      lastLifeLostAt: json['last_life_lost_at'] != null
          ? DateTime.tryParse(json['last_life_lost_at'].toString())
          : null,
      nextRegenIn: nextRegenSec != null
          ? Duration(seconds: nextRegenSec)
          : null,
      nextRegenAt: nextRegenAt,
      serverCanPlay: canPlay,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'current_lives': currentLives,
    'max_lives': maxLives,
    'last_life_lost_at': lastLifeLostAt?.toIso8601String(),
    'next_regen_in_seconds': nextRegenIn?.inSeconds,
    'next_regen_at': nextRegenAt?.toIso8601String(),
    'can_play': serverCanPlay,
  };
}

bool? _parseNullableBool(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    return raw != 0;
  }
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}
