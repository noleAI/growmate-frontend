/// Response model for POST /api/v1/quiz/submit.
class QuizSubmitResponse {
  const QuizSubmitResponse({
    required this.sessionId,
    required this.questionId,
    required this.isCorrect,
    required this.explanation,
    this.livesRemaining,
    this.canPlay,
    this.nextRegenInSeconds,
  });

  final String sessionId;
  final String questionId;
  final bool isCorrect;
  final String explanation;
  final int? livesRemaining;
  final bool? canPlay;
  final int? nextRegenInSeconds;

  factory QuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      questionId: (json['question_id'] ?? '').toString(),
      isCorrect: json['is_correct'] == true,
      explanation: (json['explanation'] ?? '').toString(),
      livesRemaining: json['lives_remaining'] as int?,
      canPlay: json['can_play'] as bool?,
      nextRegenInSeconds: json['next_regen_in_seconds'] as int?,
    );
  }
}

/// Một lựa chọn trong câu hỏi quiz, kèm ID từ backend.
class QuizOption {
  const QuizOption({required this.id, required this.text});

  /// Option ID (e.g. "A", "B", "C", "D") — sent back to backend on submit.
  final String id;

  /// Display text for the option.
  final String text;

  factory QuizOption.fromJson(dynamic json) {
    if (json is Map) {
      return QuizOption(
        id: (json['id'] ?? '').toString(),
        text: (json['text'] ?? json.values.first ?? '').toString(),
      );
    }
    // Fallback for plain-string options (shouldn't happen with real backend).
    return QuizOption(id: json.toString(), text: json.toString());
  }

  @override
  String toString() => text;
}

/// A single question returned by GET /api/v1/quiz/next.
class QuizNextQuestion {
  const QuizNextQuestion({
    required this.questionId,
    required this.content,
    required this.options,
    required this.type,
    this.sessionId,
    this.difficultyLevel,
    this.mediaUrl,
    this.index,
    this.totalQuestions,
    this.progressPercent,
    this.subQuestions,
    this.generalHint,
    this.metadata,
  });

  final String questionId;
  final String content;
  final List<QuizOption> options;
  final String type;
  final String? sessionId;
  final int? difficultyLevel;
  final String? mediaUrl;
  final int? index;
  final int? totalQuestions;
  final double? progressPercent;
  final List<Map<String, dynamic>>? subQuestions;
  final String? generalHint;
  final Map<String, dynamic>? metadata;

  factory QuizNextQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <QuizOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        options.add(QuizOption.fromJson(o));
      }
    }

    final rawSubQuestions = json['sub_questions'];
    List<Map<String, dynamic>>? subQuestions;
    if (rawSubQuestions is List) {
      subQuestions = rawSubQuestions
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    return QuizNextQuestion(
      questionId: (json['question_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      options: options,
      type: (json['question_type'] ?? json['type'] ?? 'multiple_choice')
          .toString(),
      sessionId: json['session_id']?.toString(),
      difficultyLevel: json['difficulty_level'] as int?,
      mediaUrl: json['media_url']?.toString(),
      index: json['index'] as int?,
      totalQuestions: json['total_questions'] as int?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble(),
      subQuestions: subQuestions,
      generalHint: json['general_hint']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

/// Response model for GET /api/v1/quiz/next.
class QuizNextResponse {
  const QuizNextResponse({
    required this.status,
    required this.sessionId,
    this.mode,
    this.timerSec,
    this.nextQuestion,
  });

  final String status;
  final String sessionId;
  final String? mode;
  final int? timerSec;
  final QuizNextQuestion? nextQuestion;

  bool get isCompleted => status == 'completed';

  factory QuizNextResponse.fromJson(Map<String, dynamic> json) {
    final nextQ = json['next_question'] is Map
        ? Map<String, dynamic>.from(json['next_question'] as Map)
        : null;

    // session_id lives inside next_question during active play;
    // only appears at top level for 'completed' status.
    final sessionId = (json['session_id'] ?? nextQ?['session_id'] ?? '')
        .toString();

    return QuizNextResponse(
      status: (json['status'] ?? 'ok').toString(),
      sessionId: sessionId,
      mode: json['mode']?.toString(),
      timerSec: json['timer_sec'] as int?,
      nextQuestion: nextQ != null ? QuizNextQuestion.fromJson(nextQ) : null,
    );
  }
}
