import '../entities/quiz_question_template.dart';

sealed class QuizQuestionUserAnswer {
  const QuizQuestionUserAnswer();

  Map<String, dynamic> toJson();
}

class MultipleChoiceUserAnswer extends QuizQuestionUserAnswer {
  const MultipleChoiceUserAnswer({required this.selectedOptionId});

  final String selectedOptionId;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'selected_option_id': selectedOptionId};
  }
}

class TrueFalseClusterUserAnswer extends QuizQuestionUserAnswer {
  const TrueFalseClusterUserAnswer({required this.subAnswers});

  final Map<String, bool> subAnswers;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'sub_answers': subAnswers};
  }
}

class ShortAnswerUserAnswer extends QuizQuestionUserAnswer {
  const ShortAnswerUserAnswer({required this.answerText});

  final String answerText;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'answer_text': answerText};
  }
}

class QuizQuestionEvaluation {
  const QuizQuestionEvaluation({
    required this.score,
    required this.maxScore,
    required this.isCorrect,
    this.details = const <String, dynamic>{},
  });

  final double score;
  final double maxScore;
  final bool isCorrect;
  final Map<String, dynamic> details;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'score': score,
      'max_score': maxScore,
      'is_correct': isCorrect,
      'details': details,
    };
  }
}

class ThptMath2026Scoring {
  static const Map<int, double> _trueFalseProgressiveScale = <int, double>{
    0: 0.0,
    1: 0.1,
    2: 0.25,
    3: 0.5,
    4: 1.0,
  };

  static double maxScoreForQuestionType(QuizQuestionType type) {
    return switch (type) {
      QuizQuestionType.multipleChoice => 0.25,
      QuizQuestionType.trueFalseCluster => 1.0,
      QuizQuestionType.shortAnswer => 0.5,
    };
  }

  static Map<int, double> trueFalseProgressiveScale() {
    return Map<int, double>.from(_trueFalseProgressiveScale);
  }

  static QuizQuestionEvaluation evaluate({
    required QuizQuestionTemplate question,
    required QuizQuestionUserAnswer answer,
  }) {
    switch (question.questionType) {
      case QuizQuestionType.multipleChoice:
        if (answer is! MultipleChoiceUserAnswer) {
          throw ArgumentError(
            'Expected MultipleChoiceUserAnswer for MULTIPLE_CHOICE question.',
          );
        }
        return _evaluateMultipleChoice(question.payload, answer);
      case QuizQuestionType.trueFalseCluster:
        if (answer is! TrueFalseClusterUserAnswer) {
          throw ArgumentError(
            'Expected TrueFalseClusterUserAnswer for TRUE_FALSE_CLUSTER question.',
          );
        }
        return _evaluateTrueFalseCluster(question.payload, answer);
      case QuizQuestionType.shortAnswer:
        if (answer is! ShortAnswerUserAnswer) {
          throw ArgumentError(
            'Expected ShortAnswerUserAnswer for SHORT_ANSWER question.',
          );
        }
        return _evaluateShortAnswer(question.payload, answer);
    }
  }

  static double sumTotalScore(Iterable<QuizQuestionEvaluation> evaluations) {
    final raw = evaluations.fold<double>(0, (sum, item) => sum + item.score);
    return _round3(raw);
  }

  static QuizQuestionEvaluation _evaluateMultipleChoice(
    QuizQuestionPayload payload,
    MultipleChoiceUserAnswer answer,
  ) {
    if (payload is! MultipleChoicePayload) {
      throw ArgumentError('Invalid payload for MULTIPLE_CHOICE question.');
    }

    final expected = _normalizeId(payload.correctOptionId);
    final selected = _normalizeId(answer.selectedOptionId);
    final isCorrect = expected.isNotEmpty && selected == expected;
    final score = isCorrect ? 0.25 : 0.0;

    return QuizQuestionEvaluation(
      score: score,
      maxScore: 0.25,
      isCorrect: isCorrect,
      details: <String, dynamic>{
        'selected_option_id': answer.selectedOptionId,
        'correct_option_id': payload.correctOptionId,
      },
    );
  }

  static QuizQuestionEvaluation _evaluateTrueFalseCluster(
    QuizQuestionPayload payload,
    TrueFalseClusterUserAnswer answer,
  ) {
    if (payload is! TrueFalseClusterPayload) {
      throw ArgumentError('Invalid payload for TRUE_FALSE_CLUSTER question.');
    }

    final statements = payload.subQuestions;
    if (statements.isEmpty) {
      return const QuizQuestionEvaluation(
        score: 0,
        maxScore: 1,
        isCorrect: false,
        details: <String, dynamic>{'reason': 'Payload has no sub_questions.'},
      );
    }

    var correctCount = 0;
    for (final statement in statements) {
      final picked = answer.subAnswers[statement.id];
      if (picked == null) {
        continue;
      }
      if (picked == statement.isTrue) {
        correctCount += 1;
      }
    }

    final totalStatements = statements.length;
    final isCanonicalCluster = totalStatements == 4;

    final score = isCanonicalCluster
        ? (_trueFalseProgressiveScale[correctCount] ?? 0.0)
        : correctCount / totalStatements;

    return QuizQuestionEvaluation(
      score: _round3(score),
      maxScore: 1.0,
      isCorrect: correctCount == totalStatements,
      details: <String, dynamic>{
        'correct_count': correctCount,
        'total_statements': totalStatements,
        'scoring_mode': isCanonicalCluster ? 'progressive_2026' : 'linear',
      },
    );
  }

  static QuizQuestionEvaluation _evaluateShortAnswer(
    QuizQuestionPayload payload,
    ShortAnswerUserAnswer answer,
  ) {
    if (payload is! ShortAnswerPayload) {
      throw ArgumentError('Invalid payload for SHORT_ANSWER question.');
    }

    final normalizedInput = _normalizeTextAnswer(answer.answerText);
    final normalizedAccepted = <String>{
      _normalizeTextAnswer(payload.exactAnswer),
      ...payload.acceptedAnswers.map(_normalizeTextAnswer),
    }..removeWhere((item) => item.isEmpty);

    final textMatched = normalizedAccepted.contains(normalizedInput);

    var toleranceMatched = false;
    final tolerance = payload.tolerance;
    if (!textMatched && tolerance != null && tolerance >= 0) {
      final inputNumeric = _tryParseNumeric(answer.answerText);
      final exactNumeric = _tryParseNumeric(payload.exactAnswer);
      if (inputNumeric != null && exactNumeric != null) {
        toleranceMatched = (inputNumeric - exactNumeric).abs() <= tolerance;
      }
    }

    final isCorrect = textMatched || toleranceMatched;

    final matchedBy = textMatched
        ? 'accepted_answers'
        : toleranceMatched
        ? 'tolerance'
        : 'none';

    return QuizQuestionEvaluation(
      score: isCorrect ? 0.5 : 0.0,
      maxScore: 0.5,
      isCorrect: isCorrect,
      details: <String, dynamic>{
        'submitted': answer.answerText,
        'normalized_submitted': normalizedInput,
        'matched_by': matchedBy,
        ...?(tolerance != null
            ? <String, dynamic>{'tolerance': tolerance}
            : null),
      },
    );
  }

  static String _normalizeId(String value) {
    return value.trim().toUpperCase();
  }

  static String _normalizeTextAnswer(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '').replaceAll(',', '.');
  }

  static double? _tryParseNumeric(String raw) {
    final match = RegExp(
      r'[-+]?\d+(?:[\.,]\d+)?(?:\s*/\s*[-+]?\d+(?:[\.,]\d+)?)?',
    ).firstMatch(raw);

    if (match == null) {
      return null;
    }

    final token = match.group(0);
    if (token == null || token.isEmpty) {
      return null;
    }

    final cleaned = token.replaceAll(' ', '').replaceAll(',', '.');

    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length != 2) {
        return null;
      }

      final numerator = double.tryParse(parts[0]);
      final denominator = double.tryParse(parts[1]);

      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }

      return numerator / denominator;
    }

    return double.tryParse(cleaned);
  }

  static double _round3(double value) {
    return (value * 1000).round() / 1000;
  }
}
