/// Model representing the user's daily LLM chat quota.
class QuotaStatus {
  const QuotaStatus({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final int used;
  final int limit;
  final int remaining;

  bool get isExceeded => remaining <= 0;

  double get usagePercent => limit > 0 ? (used / limit).clamp(0.0, 1.0) : 1.0;

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    final used = json['used'] as int? ?? 0;
    final limit = json['limit'] as int? ?? 20;
    final remaining = json['remaining'] as int? ?? (limit - used);
    return QuotaStatus(used: used, limit: limit, remaining: remaining);
  }

  /// Fallback for when the API is unavailable.
  static const QuotaStatus defaultQuota = QuotaStatus(
    used: 0,
    limit: 20,
    remaining: 20,
  );
}
