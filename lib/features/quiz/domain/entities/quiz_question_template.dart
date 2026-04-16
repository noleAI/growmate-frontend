import '../../data/models/quiz_api_models.dart';

enum QuizQuestionType {
  multipleChoice,
  trueFalseCluster,
  shortAnswer;

  String get storageValue => switch (this) {
    QuizQuestionType.multipleChoice => 'MULTIPLE_CHOICE',
    QuizQuestionType.trueFalseCluster => 'TRUE_FALSE_CLUSTER',
    QuizQuestionType.shortAnswer => 'SHORT_ANSWER',
  };

  static QuizQuestionType fromStorageValue(String raw) {
    final normalized = raw.trim().toUpperCase();
    return switch (normalized) {
      'MULTIPLE_CHOICE' => QuizQuestionType.multipleChoice,
      'TRUE_FALSE_CLUSTER' => QuizQuestionType.trueFalseCluster,
      'SHORT_ANSWER' => QuizQuestionType.shortAnswer,
      _ => throw ArgumentError('Unsupported question_type: $raw'),
    };
  }
}

/// Hypothesis tags for the narrowed scope: "Đạo hàm cơ bản" (4 hypotheses).
enum HypothesisTag {
  h01TrigDerivative, // Đạo hàm lượng giác (sin, cos, tan)
  h02ExpLogDerivative, // Đạo hàm mũ & logarit (eˣ, ln x)
  h03ChainRule, // Chain Rule (hàm hợp)
  h04BasicRules; // Quy tắc tính (tổng, hiệu, tích, thương)

  String get storageValue => switch (this) {
    HypothesisTag.h01TrigDerivative => 'H01',
    HypothesisTag.h02ExpLogDerivative => 'H02',
    HypothesisTag.h03ChainRule => 'H03',
    HypothesisTag.h04BasicRules => 'H04',
  };

  String get displayName => switch (this) {
    HypothesisTag.h01TrigDerivative => 'Đạo hàm lượng giác',
    HypothesisTag.h02ExpLogDerivative => 'Đạo hàm mũ & logarit',
    HypothesisTag.h03ChainRule => 'Chain Rule',
    HypothesisTag.h04BasicRules => 'Quy tắc tính',
  };

  static HypothesisTag? fromStorageValue(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    return switch (normalized) {
      'H01' => HypothesisTag.h01TrigDerivative,
      'H02' => HypothesisTag.h02ExpLogDerivative,
      'H03' => HypothesisTag.h03ChainRule,
      'H04' => HypothesisTag.h04BasicRules,
      _ => null,
    };
  }
}

class QuizQuestionTemplate {
  const QuizQuestionTemplate({
    required this.id,
    required this.subject,
    required this.topicCode,
    required this.topicName,
    required this.examYear,
    required this.questionType,
    required this.partNo,
    required this.difficultyLevel,
    required this.content,
    required this.payload,
    required this.isActive,
    this.hypothesisTag,
    this.mediaUrl,
    this.metadata = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
    this.publishedBy,
  });

  final String id;
  final String subject;
  final String? topicCode;
  final String? topicName;
  final int examYear;
  final QuizQuestionType questionType;
  final int partNo;
  final int difficultyLevel;
  final String content;
  final String? mediaUrl;
  final HypothesisTag? hypothesisTag;
  final QuizQuestionPayload payload;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? publishedBy;

  factory QuizQuestionTemplate.fromJson(Map<String, dynamic> json) {
    final questionType = QuizQuestionType.fromStorageValue(
      json['question_type']?.toString() ?? '',
    );

    final payloadJson = _toMap(json['payload']);

    return QuizQuestionTemplate(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'math',
      topicCode: json['topic_code']?.toString(),
      topicName: json['topic_name']?.toString(),
      examYear: _safeInt(json['exam_year'], fallback: 2026),
      questionType: questionType,
      partNo: _safeInt(json['part_no'], fallback: _partFromType(questionType)),
      difficultyLevel: _safeInt(json['difficulty_level'], fallback: 2),
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      hypothesisTag: HypothesisTag.fromStorageValue(
        json['hypothesis_tag']?.toString(),
      ),
      payload: QuizQuestionPayload.fromJson(questionType, payloadJson),
      metadata: _toMap(json['metadata']),
      isActive: _safeBool(json['is_active'], fallback: true),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      publishedBy: json['published_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'subject': subject,
      'topic_code': topicCode,
      'topic_name': topicName,
      'exam_year': examYear,
      'question_type': questionType.storageValue,
      'part_no': partNo,
      'difficulty_level': difficultyLevel,
      'content': content,
      'media_url': mediaUrl,
      'hypothesis_tag': hypothesisTag?.storageValue,
      'payload': payload.toJson(),
      'metadata': metadata,
      'is_active': isActive,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'published_by': publishedBy,
    };
  }

  static int _partFromType(QuizQuestionType type) {
    return switch (type) {
      QuizQuestionType.multipleChoice => 1,
      QuizQuestionType.trueFalseCluster => 2,
      QuizQuestionType.shortAnswer => 3,
    };
  }

  /// Convert a backend API response into a [QuizQuestionTemplate].
  ///
  /// Used when quiz questions come from `GET /quiz/next` (backend-driven mode)
  /// instead of from the local Supabase table.
  factory QuizQuestionTemplate.fromApiResponse(QuizNextQuestion apiQ) {
    final questionType = QuizQuestionType.fromStorageValue(apiQ.type);

    final QuizQuestionPayload payload;
    switch (questionType) {
      case QuizQuestionType.multipleChoice:
        payload = MultipleChoicePayload(
          options: apiQ.options
              .map((o) => MultipleChoiceOption(id: o.id, text: o.text))
              .toList(growable: false),
          // Backend doesn't expose correct answer during delivery.
          correctOptionId: '',
          explanation: '',
        );
      case QuizQuestionType.trueFalseCluster:
        final subs = apiQ.subQuestions ?? const [];
        payload = TrueFalseClusterPayload(
          subQuestions: subs
              .map(
                (s) => TrueFalseStatement(
                  id: (s['id'] ?? '').toString(),
                  text: (s['text'] ?? '').toString(),
                  isTrue: false, // unknown during delivery
                  explanation: '',
                ),
              )
              .toList(growable: false),
          generalHint: apiQ.generalHint ?? '',
        );
      case QuizQuestionType.shortAnswer:
        payload = const ShortAnswerPayload(
          exactAnswer: '',
          acceptedAnswers: [],
          explanation: '',
        );
    }

    return QuizQuestionTemplate(
      id: apiQ.questionId,
      subject: 'math',
      topicCode: null,
      topicName: null,
      examYear: 2026,
      questionType: questionType,
      partNo: _partFromType(questionType),
      difficultyLevel: apiQ.difficultyLevel ?? 2,
      content: apiQ.content,
      mediaUrl: apiQ.mediaUrl,
      payload: payload,
      isActive: true,
      metadata: apiQ.metadata ?? const {},
    );
  }
}

sealed class QuizQuestionPayload {
  const QuizQuestionPayload();

  factory QuizQuestionPayload.fromJson(
    QuizQuestionType type,
    Map<String, dynamic> json,
  ) {
    return switch (type) {
      QuizQuestionType.multipleChoice => MultipleChoicePayload.fromJson(json),
      QuizQuestionType.trueFalseCluster => TrueFalseClusterPayload.fromJson(
        json,
      ),
      QuizQuestionType.shortAnswer => ShortAnswerPayload.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

class MultipleChoicePayload extends QuizQuestionPayload {
  const MultipleChoicePayload({
    required this.options,
    required this.correctOptionId,
    required this.explanation,
  });

  final List<MultipleChoiceOption> options;
  final String correctOptionId;
  final String explanation;

  factory MultipleChoicePayload.fromJson(Map<String, dynamic> json) {
    final options = _toListOfMap(
      json['options'],
    ).map(MultipleChoiceOption.fromJson).toList(growable: false);

    return MultipleChoicePayload(
      options: options,
      correctOptionId: json['correct_option_id']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'options': options.map((item) => item.toJson()).toList(growable: false),
      'correct_option_id': correctOptionId,
      'explanation': explanation,
    };
  }
}

class MultipleChoiceOption {
  const MultipleChoiceOption({required this.id, required this.text});

  final String id;
  final String text;

  factory MultipleChoiceOption.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'text': text};
  }
}

class TrueFalseClusterPayload extends QuizQuestionPayload {
  const TrueFalseClusterPayload({
    required this.subQuestions,
    required this.generalHint,
  });

  final List<TrueFalseStatement> subQuestions;
  final String generalHint;

  factory TrueFalseClusterPayload.fromJson(Map<String, dynamic> json) {
    final subQuestions = _toListOfMap(
      json['sub_questions'],
    ).map(TrueFalseStatement.fromJson).toList(growable: false);

    return TrueFalseClusterPayload(
      subQuestions: subQuestions,
      generalHint: json['general_hint']?.toString() ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sub_questions': subQuestions
          .map((item) => item.toJson())
          .toList(growable: false),
      'general_hint': generalHint,
    };
  }
}

class TrueFalseStatement {
  const TrueFalseStatement({
    required this.id,
    required this.text,
    required this.isTrue,
    required this.explanation,
  });

  final String id;
  final String text;
  final bool isTrue;
  final String explanation;

  factory TrueFalseStatement.fromJson(Map<String, dynamic> json) {
    return TrueFalseStatement(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isTrue: _safeBool(json['is_true'], fallback: false),
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'is_true': isTrue,
      'explanation': explanation,
    };
  }
}

class ShortAnswerPayload extends QuizQuestionPayload {
  const ShortAnswerPayload({
    required this.exactAnswer,
    required this.acceptedAnswers,
    required this.explanation,
    this.unit,
    this.tolerance,
  });

  final String exactAnswer;
  final List<String> acceptedAnswers;
  final String? unit;
  final String explanation;
  final double? tolerance;

  factory ShortAnswerPayload.fromJson(Map<String, dynamic> json) {
    return ShortAnswerPayload(
      exactAnswer: json['exact_answer']?.toString() ?? '',
      acceptedAnswers: _toStringList(json['accepted_answers']),
      unit: json['unit']?.toString(),
      explanation: json['explanation']?.toString() ?? '',
      tolerance: _safeDouble(json['tolerance']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exact_answer': exactAnswer,
      'accepted_answers': acceptedAnswers,
      'unit': unit,
      'explanation': explanation,
      if (tolerance != null) 'tolerance': tolerance,
    };
  }
}

Map<String, dynamic> _toMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toListOfMap(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<String> _toStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value.map((item) => item.toString()).toList(growable: false);
}

int _safeInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _safeBool(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return fallback;
}

double? _safeDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _toDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
