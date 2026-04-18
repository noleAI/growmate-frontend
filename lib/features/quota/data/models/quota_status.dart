/// Model representing the user's daily LLM chat quota.
class QuotaStatus {
  const QuotaStatus({
    required this.used,
    required this.limit,
    required this.remaining,
    this.resetAt,
  });

  final int used;
  final int limit;
  final int remaining;
  final DateTime? resetAt;

  bool get isExceeded => remaining <= 0;

  double get usagePercent => limit > 0 ? (used / limit).clamp(0.0, 1.0) : 1.0;

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    final used = _toInt(json['used']) ?? 0;
    final limit = _toInt(json['limit']) ?? 30;
    final remaining = _toInt(json['remaining']) ?? (limit - used);
    final resetAt = DateTime.tryParse(json['reset_at']?.toString() ?? '');

    return QuotaStatus(
      used: used,
      limit: limit,
      remaining: remaining.clamp(0, limit),
      resetAt: resetAt,
    );
  }

  factory QuotaStatus.fromRateLimitDetails(
    Map<String, dynamic>? details, {
    int fallbackLimit = 30,
  }) {
    final used = _toInt(details?['used']) ?? fallbackLimit;
    final limit = _toInt(details?['limit']) ?? fallbackLimit;
    return QuotaStatus(used: used, limit: limit, remaining: 0);
  }

  QuotaStatus copyWith({
    int? used,
    int? limit,
    int? remaining,
    DateTime? resetAt,
  }) {
    return QuotaStatus(
      used: used ?? this.used,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
      resetAt: resetAt ?? this.resetAt,
    );
  }

  /// Fallback for when the API is unavailable.
  static const QuotaStatus defaultQuota = QuotaStatus(
    used: 0,
    limit: 30,
    remaining: 30,
  );

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
