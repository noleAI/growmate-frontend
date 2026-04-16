/// Model for a pending session returned by GET /api/v1/sessions/pending.
class PendingSession {
  const PendingSession({
    required this.hasPending,
    this.sessionId,
    this.status,
    this.lastQuestionIndex,
    this.totalQuestions,
    this.progressPercent,
    this.lastActiveAt,
    this.abandonedAt,
  });

  final bool hasPending;
  final String? sessionId;
  final String? status;
  final int? lastQuestionIndex;
  final int? totalQuestions;
  final int? progressPercent;
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
      lastQuestionIndex: session?['last_question_index'] as int?,
      totalQuestions: session?['total_questions'] as int?,
      progressPercent: session?['progress_percent'] as int?,
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
