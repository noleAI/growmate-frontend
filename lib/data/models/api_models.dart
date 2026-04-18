class SubmitAnswerResponse {
  const SubmitAnswerResponse({
    required this.submissionId,
    required this.answerId,
    required this.questionId,
    required this.isCorrect,
    required this.raw,
  });

  final String submissionId;
  final String answerId;
  final String questionId;
  final bool isCorrect;
  final Map<String, dynamic> raw;

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResponse(
      submissionId: _readString(json, const <String>[
        'submissionId',
        'submission_id',
      ]),
      answerId: _readString(json, const <String>['answerId', 'answer_id']),
      questionId: _readString(json, const <String>[
        'questionId',
        'question_id',
      ]),
      isCorrect: _readBool(json, const <String>['isCorrect', 'is_correct']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  String toString() {
    return 'SubmitAnswerResponse(submissionId: $submissionId, answerId: $answerId, questionId: $questionId, isCorrect: $isCorrect)';
  }
}

class DiagnosisResponse {
  const DiagnosisResponse({
    required this.diagnosisId,
    required this.title,
    required this.gapAnalysis,
    required this.summary,
    required this.diagnosisReason,
    required this.strengths,
    required this.needsReview,
    required this.mode,
    required this.requiresHitl,
    required this.confidence,
    required this.riskLevel,
    required this.nextSuggestedTopic,
    required this.interventionPlan,
    required this.raw,
    this.planRepaired = false,
    this.beliefEntropy = 0.0,
    this.formulaRecommendations = const [],
  });

  final String diagnosisId;
  final String title;
  final String gapAnalysis;
  final String summary;
  final String diagnosisReason;
  final List<String> strengths;
  final List<String> needsReview;
  final String mode;
  final bool requiresHitl;
  final double confidence;
  final String riskLevel;
  final String nextSuggestedTopic;
  final List<Map<String, dynamic>> interventionPlan;
  final Map<String, dynamic> raw;

  /// Whether the agentic planner had to repair its plan for this diagnosis.
  final bool planRepaired;

  /// Bayesian belief entropy from the backend.
  final double beliefEntropy;

  /// Formula recommendations from the data-driven pipeline.
  final List<Map<String, dynamic>> formulaRecommendations;

  factory DiagnosisResponse.fromJson(Map<String, dynamic> json) {
    return DiagnosisResponse(
      diagnosisId: _readString(json, const <String>[
        'diagnosisId',
        'diagnosis_id',
      ]),
      title: _readString(json, const <String>['title']),
      gapAnalysis: _readString(json, const <String>[
        'gapAnalysis',
        'gap_analysis',
      ]),
      summary: _readString(json, const <String>['summary']),
      diagnosisReason: _readString(json, const <String>[
        'diagnosisReason',
        'diagnosis_reason',
      ]),
      strengths: _readStringList(json, const <String>['strengths']),
      needsReview: _readStringList(json, const <String>[
        'needsReview',
        'needs_review',
      ]),
      mode: _readString(json, const <String>['mode']),
      requiresHitl: _readBool(json, const <String>[
        'requiresHITL',
        'requiresHitl',
        'requires_hitl',
      ]),
      confidence: _readDouble(json, const <String>[
        'confidence',
        'confidenceScore',
        'confidence_score',
      ]),
      riskLevel: _readString(json, const <String>['riskLevel', 'risk_level']),
      nextSuggestedTopic: _readString(json, const <String>[
        'nextSuggestedTopic',
        'next_suggested_topic',
      ]),
      interventionPlan: _readMapList(json, const <String>[
        'interventionPlan',
        'intervention_plan',
      ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  String toString() {
    return 'DiagnosisResponse(diagnosisId: $diagnosisId, mode: $mode, requiresHitl: $requiresHitl, confidence: $confidence, riskLevel: $riskLevel, strengths: ${strengths.length}, needsReview: ${needsReview.length}, interventionPlan: ${interventionPlan.length})';
  }
}

class HITLConfirmResponse {
  const HITLConfirmResponse({
    required this.hitlDecision,
    required this.finalMode,
    required this.interventionPlan,
    required this.raw,
  });

  final String hitlDecision;
  final String finalMode;
  final List<Map<String, dynamic>> interventionPlan;
  final Map<String, dynamic> raw;

  factory HITLConfirmResponse.fromJson(Map<String, dynamic> json) {
    return HITLConfirmResponse(
      hitlDecision: _readString(json, const <String>[
        'hitlDecision',
        'hitl_decision',
      ]),
      finalMode: _readString(json, const <String>['finalMode', 'final_mode']),
      interventionPlan: _readMapList(json, const <String>[
        'interventionPlan',
        'intervention_plan',
      ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  String toString() {
    return 'HITLConfirmResponse(hitlDecision: $hitlDecision, finalMode: $finalMode, interventionPlan: ${interventionPlan.length})';
  }
}

class InterventionFeedbackResponse {
  const InterventionFeedbackResponse({
    required this.updatedQValues,
    required this.selectedOption,
    this.topic,
    this.nextAction,
    this.durationMinutes,
    this.focusScore,
    this.confidenceScore,
    required this.raw,
  });

  final Map<String, dynamic> updatedQValues;
  final Map<String, dynamic> selectedOption;
  final String? topic;
  final String? nextAction;
  final int? durationMinutes;
  final double? focusScore;
  final double? confidenceScore;
  final Map<String, dynamic> raw;

  factory InterventionFeedbackResponse.fromJson(Map<String, dynamic> json) {
    final completion = _readMap(json, const <String>[
      'completion',
      'session_completion',
      'sessionCompletion',
    ]);
    final selectedOption = _readMap(json, const <String>[
      'selectedOption',
      'selected_option',
    ]);

    return InterventionFeedbackResponse(
      updatedQValues: _readMap(json, const <String>[
        'updatedQValues',
        'updated_q_values',
      ]),
      selectedOption: selectedOption,
      topic: _firstNonEmptyString(<String>[
        _readString(completion, const <String>['topic']),
        _readString(json, const <String>['topic']),
        _readString(json, const <String>[
          'nextSuggestedTopic',
          'next_suggested_topic',
        ]),
        _readString(selectedOption, const <String>['label']),
      ]),
      nextAction: _firstNonEmptyString(<String>[
        _readString(completion, const <String>['nextAction', 'next_action']),
        _readString(json, const <String>['nextAction', 'next_action']),
        _readString(selectedOption, const <String>['label']),
      ]),
      durationMinutes:
          _readNullableInt(completion, const <String>[
            'durationMinutes',
            'duration_minutes',
          ]) ??
          _readNullableInt(selectedOption, const <String>[
            'durationMinutes',
            'duration_minutes',
          ]) ??
          _readNullableInt(json, const <String>[
            'durationMinutes',
            'duration_minutes',
          ]),
      focusScore:
          _readNullableDouble(completion, const <String>[
            'focusScore',
            'focus',
          ]) ??
          _readNullableDouble(json, const <String>['focusScore', 'focus']),
      confidenceScore:
          _readNullableDouble(completion, const <String>[
            'confidenceScore',
            'confidence',
          ]) ??
          _readNullableDouble(json, const <String>[
            'confidenceScore',
            'confidence',
          ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  String toString() {
    return 'InterventionFeedbackResponse(updatedQValues: ${updatedQValues.keys.toList()}, selectedOption: $selectedOption, topic: $topic, nextAction: $nextAction)';
  }
}

class InteractionFeedbackResponse {
  const InteractionFeedbackResponse({
    required this.eventId,
    required this.savedAt,
    required this.nextSuggestedTopic,
    required this.raw,
  });

  final String eventId;
  final DateTime? savedAt;
  final String nextSuggestedTopic;
  final Map<String, dynamic> raw;

  factory InteractionFeedbackResponse.fromJson(Map<String, dynamic> json) {
    final rawSavedAt = _readString(json, const <String>['savedAt', 'saved_at']);

    return InteractionFeedbackResponse(
      eventId: _readString(json, const <String>['eventId', 'event_id']),
      savedAt: rawSavedAt.isEmpty ? null : DateTime.tryParse(rawSavedAt),
      nextSuggestedTopic: _readString(json, const <String>[
        'nextSuggestedTopic',
        'next_suggested_topic',
      ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  @override
  String toString() {
    return 'InteractionFeedbackResponse(eventId: $eventId, savedAt: $savedAt, nextSuggestedTopic: $nextSuggestedTopic)';
  }
}

Object? _readAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value == null) {
    return '';
  }
  return value.toString();
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readMapList(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _readAny(json, keys);
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String? _firstNonEmptyString(Iterable<String> values) {
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _readAny(json, keys);
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
