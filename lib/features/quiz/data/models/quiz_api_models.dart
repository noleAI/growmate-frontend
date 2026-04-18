/// Response model for POST /api/v1/quiz/submit.
class QuizSubmitResponse {
  const QuizSubmitResponse({
    required this.sessionId,
    required this.questionId,
    required this.isCorrect,
    required this.explanation,
    this.score,
    this.maxScore,
    this.progressPercent,
    this.lastQuestionIndex,
    this.totalQuestions,
    this.quizSummary,
    this.livesRemaining,
    this.canPlay,
    this.nextRegenInSeconds,
  });

  final String sessionId;
  final String questionId;
  final bool isCorrect;
  final String explanation;

  /// Score awarded for this question (e.g. 1.0 for correct, 0.0 for incorrect).
  final double? score;

  /// Maximum possible score for this question.
  final double? maxScore;

  /// Overall session progress as percentage (0-100).
  final int? progressPercent;

  /// Index of the last answered question (1-based from backend).
  final int? lastQuestionIndex;

  /// Total number of questions in this quiz session.
  final int? totalQuestions;

  /// Running score summary for the entire session so far.
  final QuizSessionScoreSummary? quizSummary;

  final int? livesRemaining;
  final bool? canPlay;
  final int? nextRegenInSeconds;

  factory QuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['quiz_summary'];
    QuizSessionScoreSummary? quizSummary;
    if (rawSummary is Map) {
      quizSummary = QuizSessionScoreSummary.fromJson(
        Map<String, dynamic>.from(rawSummary),
      );
    }

    return QuizSubmitResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      questionId: (json['question_id'] ?? '').toString(),
      isCorrect: json['is_correct'] == true,
      explanation: (json['explanation'] ?? '').toString(),
      score: _toDouble(json['score']),
      maxScore: _toDouble(json['max_score']),
      progressPercent: _toInt(json['progress_percent']),
      lastQuestionIndex: _toInt(json['last_question_index']),
      totalQuestions: _toInt(json['total_questions']),
      quizSummary: quizSummary,
      livesRemaining: _toInt(json['lives_remaining']),
      canPlay: json['can_play'] as bool?,
      nextRegenInSeconds: _toInt(json['next_regen_in_seconds']),
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

/// Shared score summary payload used by result and history endpoints.
class QuizSessionScoreSummary {
  const QuizSessionScoreSummary({
    this.answeredCount = 0,
    this.correctCount = 0,
    this.totalScore = 0,
    this.maxScore = 0,
    this.accuracyPercent = 0,
  });

  final int answeredCount;
  final int correctCount;
  final double totalScore;
  final double maxScore;
  final double accuracyPercent;

  factory QuizSessionScoreSummary.fromJson(Map<String, dynamic> json) {
    return QuizSessionScoreSummary(
      answeredCount: _toInt(json['answered_count']) ?? 0,
      correctCount: _toInt(json['correct_count']) ?? 0,
      totalScore: _toDouble(json['total_score']) ?? 0,
      maxScore: _toDouble(json['max_score']) ?? 0,
      accuracyPercent: _toDouble(json['accuracy_percent']) ?? 0,
    );
  }
}

/// One submitted attempt record returned by session result endpoint.
class QuizAttemptRecord {
  const QuizAttemptRecord({
    required this.questionId,
    required this.isCorrect,
    required this.score,
    required this.maxScore,
    this.questionTemplateId,
    this.questionType,
    this.explanation,
    this.userAnswer,
    this.submittedAt,
    this.timeTakenSec,
  });

  final String questionId;
  final bool isCorrect;
  final double score;
  final double maxScore;
  final String? questionTemplateId;
  final String? questionType;
  final String? explanation;
  final Map<String, dynamic>? userAnswer;
  final DateTime? submittedAt;
  final double? timeTakenSec;

  factory QuizAttemptRecord.fromJson(Map<String, dynamic> json) {
    return QuizAttemptRecord(
      questionId: (json['question_id'] ?? '').toString(),
      isCorrect: json['is_correct'] == true,
      score: _toDouble(json['score']) ?? 0,
      maxScore: _toDouble(json['max_score']) ?? 0,
      questionTemplateId: json['question_template_id']?.toString(),
      questionType: json['question_type']?.toString(),
      explanation: json['explanation']?.toString(),
      userAnswer: json['user_answer'] is Map
          ? Map<String, dynamic>.from(json['user_answer'] as Map)
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      timeTakenSec: _toDouble(json['time_taken_sec']),
    );
  }
}

/// Response model for GET /api/v1/quiz/sessions/{session_id}/result.
class QuizSessionResultResponse {
  const QuizSessionResultResponse({
    required this.status,
    required this.sessionId,
    required this.sessionStatus,
    required this.summary,
    required this.attempts,
    this.progressPercent,
    this.lastQuestionIndex,
    this.totalQuestions,
    this.startedAt,
    this.endedAt,
  });

  final String status;
  final String sessionId;
  final String sessionStatus;
  final int? progressPercent;
  final int? lastQuestionIndex;
  final int? totalQuestions;
  final QuizSessionScoreSummary summary;
  final List<QuizAttemptRecord> attempts;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory QuizSessionResultResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : const <String, dynamic>{};
    final rawAttempts = json['attempts'];
    final attempts = <QuizAttemptRecord>[];
    if (rawAttempts is List) {
      for (final item in rawAttempts) {
        if (item is Map) {
          attempts.add(
            QuizAttemptRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return QuizSessionResultResponse(
      status: (json['status'] ?? '').toString(),
      sessionId: (json['session_id'] ?? '').toString(),
      sessionStatus: (json['session_status'] ?? '').toString(),
      progressPercent: _toInt(json['progress_percent']),
      lastQuestionIndex: _toInt(json['last_question_index']),
      totalQuestions: _toInt(json['total_questions']),
      summary: QuizSessionScoreSummary.fromJson(summaryJson),
      attempts: attempts,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
    );
  }
}

/// One history entry returned by GET /api/v1/quiz/history.
class QuizHistoryItem {
  const QuizHistoryItem({
    required this.sessionId,
    required this.status,
    required this.summary,
    this.startTime,
    this.endTime,
    this.progressPercent,
    this.lastQuestionIndex,
    this.totalQuestions,
  });

  final String sessionId;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? progressPercent;
  final int? lastQuestionIndex;
  final int? totalQuestions;
  final QuizSessionScoreSummary summary;

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : const <String, dynamic>{};
    return QuizHistoryItem(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString())
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,
      progressPercent: _toInt(json['progress_percent']),
      lastQuestionIndex: _toInt(json['last_question_index']),
      totalQuestions: _toInt(json['total_questions']),
      summary: QuizSessionScoreSummary.fromJson(summaryJson),
    );
  }
}

/// Response model for GET /api/v1/quiz/history.
class QuizHistoryResponse {
  const QuizHistoryResponse({
    required this.status,
    required this.total,
    required this.limit,
    required this.offset,
    required this.items,
  });

  final String status;
  final int total;
  final int limit;
  final int offset;
  final List<QuizHistoryItem> items;

  factory QuizHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <QuizHistoryItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(QuizHistoryItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return QuizHistoryResponse(
      status: (json['status'] ?? '').toString(),
      total: _toInt(json['total']) ?? 0,
      limit: _toInt(json['limit']) ?? 0,
      offset: _toInt(json['offset']) ?? 0,
      items: items,
    );
  }
}

int? _toInt(Object? raw) {
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

double? _toDouble(Object? raw) {
  if (raw is double) {
    return raw;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw);
  }
  return null;
}
