/// Model for a pending session returned by GET /api/v1/sessions/pending.
class PendingSession {
  const PendingSession({
    required this.hasPending,
    this.sessionId,
    this.status,
    this.lastQuestionIndex,
    this.nextQuestionIndex,
    this.totalQuestions,
    this.progressPercent,
    this.mode,
    this.pauseState,
    this.pauseReason,
    this.resumeContextVersion,
    this.lastActiveAt,
    this.abandonedAt,
  });

  final bool hasPending;
  final String? sessionId;
  final String? status;
  final int? lastQuestionIndex;
  final int? nextQuestionIndex;
  final int? totalQuestions;
  final int? progressPercent;
  final String? mode;
  final bool? pauseState;
  final String? pauseReason;
  final int? resumeContextVersion;
  final DateTime? lastActiveAt;
  final DateTime? abandonedAt;

  factory PendingSession.fromJson(Map<String, dynamic> json) {
    final session = json['session'] is Map
        ? Map<String, dynamic>.from(json['session'] as Map)
        : null;
    return PendingSession(
      hasPending: json['has_pending'] == true,
      sessionId: session?['session_id']?.toString(),
      status: session?['status']?.toString(),
      lastQuestionIndex: _parseNullableInt(session?['last_question_index']),
      nextQuestionIndex: _parseNullableInt(session?['next_question_index']),
      totalQuestions: _parseNullableInt(session?['total_questions']),
      progressPercent: _parseNullableInt(session?['progress_percent']),
      mode: session?['mode']?.toString(),
      pauseState: _parseNullableBool(session?['pause_state']),
      pauseReason: session?['pause_reason']?.toString(),
      resumeContextVersion: _parseNullableInt(
        session?['resume_context_version'],
      ),
      lastActiveAt: session?['last_active_at'] != null
          ? DateTime.tryParse(session!['last_active_at'].toString())
          : null,
      abandonedAt: session?['abandoned_at'] != null
          ? DateTime.tryParse(session!['abandoned_at'].toString())
          : null,
    );
  }

  static const PendingSession empty = PendingSession(hasPending: false);
}

int? _parseNullableInt(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw);
  }
  return null;
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
