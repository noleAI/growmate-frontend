class SignalBatch {
  const SignalBatch({
    required this.questionId,
    required this.typingSpeed,
    required this.idleTime,
    required this.correctionRate,
    required this.responseTime,
    required this.capturedAt,
    required this.trigger,
  });

  final String questionId;
  final double typingSpeed;
  final double idleTime;
  final int correctionRate;
  final double? responseTime;
  final DateTime capturedAt;
  final String trigger;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'question_id': questionId,
      'typing_speed': typingSpeed,
      'idle_time': idleTime,
      'correction_rate': correctionRate,
      'response_time': responseTime,
      'captured_at': capturedAt.toIso8601String(),
      'trigger': trigger,
    };
  }

  Map<String, dynamic> toSupabaseInsert({String? sessionId, String? userId}) {
    return <String, dynamic>{
      'session_id': sessionId,
      'user_id': userId,
      'question_id': questionId,
      'typing_speed': typingSpeed,
      'idle_time': idleTime,
      'correction_rate': correctionRate,
      'response_time': responseTime,
      'trigger': trigger,
      'created_at': capturedAt.toIso8601String(),
    };
  }
}
