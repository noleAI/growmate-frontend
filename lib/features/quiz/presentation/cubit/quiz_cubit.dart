import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../core/services/mood_state_service.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/quiz_api_repository.dart';

sealed class QuizCubitState extends Equatable {
  const QuizCubitState({required this.answer});

  final String answer;

  @override
  List<Object?> get props => <Object?>[answer];
}

final class QuizIdleState extends QuizCubitState {
  const QuizIdleState({super.answer = ''});
}

final class QuizSubmittingState extends QuizCubitState {
  const QuizSubmittingState({required super.answer});
}

final class QuizSubmitSuccessState extends QuizCubitState {
  const QuizSubmitSuccessState({
    required this.submissionId,
    required super.answer,
    this.isCorrect = false,
    this.xpEarned = 0,
    this.livesRemaining,
    this.canPlay,
    this.nextRegenInSeconds,
  });

  final String submissionId;
  final bool isCorrect;
  final int xpEarned;
  final int? livesRemaining;
  final bool? canPlay;
  final int? nextRegenInSeconds;

  @override
  List<Object?> get props => <Object?>[
    ...super.props,
    submissionId,
    isCorrect,
    xpEarned,
    livesRemaining,
    canPlay,
    nextRegenInSeconds,
  ];
}

final class QuizSubmitFailureState extends QuizCubitState {
  const QuizSubmitFailureState({required this.message, required super.answer});

  final String message;

  @override
  List<Object?> get props => <Object?>[...super.props, message];
}

final class QuizRecoveryTriggeredState extends QuizCubitState {
  const QuizRecoveryTriggeredState({
    required this.reason,
    required this.submissionId,
    required this.wrongStreak,
    required super.answer,
  });

  final String reason;
  final String submissionId;
  final int wrongStreak;

  @override
  List<Object?> get props => <Object?>[
    ...super.props,
    reason,
    submissionId,
    wrongStreak,
  ];
}

final class QuizBatchSubmittingState extends QuizCubitState {
  const QuizBatchSubmittingState({required super.answer});
}

final class QuizBatchSubmitSuccessState extends QuizCubitState {
  const QuizBatchSubmitSuccessState({
    required this.totalSubmitted,
    required super.answer,
  });

  final int totalSubmitted;

  @override
  List<Object?> get props => <Object?>[...super.props, totalSubmitted];
}

/// Emitted when the backend returns 429 — daily session limit exceeded.
final class QuizRateLimitedState extends QuizCubitState {
  const QuizRateLimitedState({required this.message, required super.answer});

  final String message;

  @override
  List<Object?> get props => <Object?>[...super.props, message];
}

/// Emitted when the backend returns 403 — no lives remaining.
final class QuizNoLivesState extends QuizCubitState {
  const QuizNoLivesState({
    required this.message,
    required super.answer,
    this.nextRegenInSeconds,
  });

  final String message;
  final int? nextRegenInSeconds;

  @override
  List<Object?> get props => <Object?>[
    ...super.props,
    message,
    nextRegenInSeconds,
  ];
}

class QuizCubit extends Cubit<QuizCubitState> {
  QuizCubit({
    required QuizRepository quizRepository,
    required this.questionId,
    required this.questionText,
    QuizApiRepository? quizApiRepository,
    String? sessionId,
    BehavioralSignalService? signalService,
    MoodStateService? moodStateService,
  }) : _quizRepository = quizRepository,
       _quizApiRepository = quizApiRepository,
       _sessionId = sessionId,
       _signalService = signalService ?? BehavioralSignalService.instance,
       _moodStateService = moodStateService ?? MoodStateService.instance,
       super(const QuizIdleState());

  static int _wrongAnswersInRow = 0;

  final QuizRepository _quizRepository;
  final QuizApiRepository? _quizApiRepository;
  final String? _sessionId;
  final BehavioralSignalService _signalService;
  final MoodStateService _moodStateService;

  final String questionId;
  final String questionText;

  static void resetWrongStreak() {
    _wrongAnswersInRow = 0;
  }

  void onAnswerChanged(String answer) {
    if (state is QuizSubmittingState) {
      return;
    }

    emit(QuizIdleState(answer: answer));
  }

  Future<void> submitAnswer(String answer) async {
    final trimmedAnswer = answer.trim();

    if (trimmedAnswer.isEmpty) {
      emit(
        QuizSubmitFailureState(
          message: 'Vui lòng nhập kết quả trước khi gửi.',
          answer: answer,
        ),
      );
      return;
    }

    emit(QuizSubmittingState(answer: answer));

    try {
      final submitResponse = await _quizRepository.submitAnswer(
        questionId: questionId,
        answer: trimmedAnswer,
        context: <String, dynamic>{'questionText': questionText},
      );

      final submissionId = submitResponse.submissionId.isNotEmpty
          ? submitResponse.submissionId
          : submitResponse.answerId;

      if (submissionId.isEmpty) {
        throw Exception('Backend response missing submissionId/answerId.');
      }

      final isCorrect =
          submitResponse.isCorrect ||
          _resolveIsCorrect(submitResponse.raw, trimmedAnswer);
      if (isCorrect) {
        _wrongAnswersInRow = 0;
      } else {
        _wrongAnswersInRow += 1;
      }

      final highIdleDetected = _signalService.hasHighIdleTime();
      final wrongStreakDetected = _wrongAnswersInRow >= 3;

      if (highIdleDetected || wrongStreakDetected) {
        _moodStateService.setMood('Recovery');

        emit(
          QuizRecoveryTriggeredState(
            answer: answer,
            submissionId: submissionId,
            wrongStreak: _wrongAnswersInRow,
            reason: highIdleDetected ? 'idle_time_high' : 'three_wrong_answers',
          ),
        );
        return;
      }

      emit(
        QuizSubmitSuccessState(
          submissionId: submissionId,
          answer: answer,
          isCorrect: isCorrect,
          xpEarned: isCorrect ? 10 : 0,
        ),
      );
    } catch (_) {
      emit(
        QuizSubmitFailureState(
          message: 'Không thể gửi bài lúc này. Vui lòng thử lại.',
          answer: answer,
        ),
      );
    }
  }

  Future<void> submitTypedAnswer({
    required QuizQuestionTemplate question,
    required QuizQuestionUserAnswer userAnswer,
  }) async {
    final visibleAnswer = _visibleAnswer(userAnswer).trim();

    if (visibleAnswer.isEmpty) {
      emit(
        QuizSubmitFailureState(
          message: 'Vui lòng hoàn thành câu trả lời trước khi gửi.',
          answer: visibleAnswer,
        ),
      );
      return;
    }

    emit(QuizSubmittingState(answer: visibleAnswer));

    try {
      final evaluation = ThptMath2026Scoring.evaluate(
        question: question,
        answer: userAnswer,
      );

      await _quizRepository.recordEvaluatedAttempt(
        question: question,
        userAnswer: userAnswer,
        evaluation: evaluation,
      );

      // Use backend API when available, fall back to legacy ApiService path.
      final String submissionId;
      final bool responseIsCorrect;
      int? livesRemaining;
      bool? canPlay;
      int? nextRegenInSeconds;

      if (_quizApiRepository != null && _sessionId != null) {
        final apiSessionId = _sessionId;

        // Dispatch correct field per question type to match backend contract.
        String? selectedOption;
        String? answerField;
        Map<String, dynamic>? answersField;

        if (userAnswer is MultipleChoiceUserAnswer) {
          selectedOption = userAnswer.selectedOptionId;
        } else if (userAnswer is ShortAnswerUserAnswer) {
          answerField = userAnswer.answerText;
        } else if (userAnswer is TrueFalseClusterUserAnswer) {
          answersField = userAnswer.subAnswers.map(
            (key, value) => MapEntry(key, value),
          );
        }

        final apiResponse = await _quizApiRepository.submitAnswer(
          sessionId: apiSessionId,
          questionId: question.id,
          selectedOption: selectedOption,
          answer: answerField,
          answers: answersField,
        );
        submissionId = apiSessionId.isNotEmpty
            ? apiSessionId
            : (apiResponse.questionId.isNotEmpty
                  ? apiResponse.questionId
                  : question.id);
        responseIsCorrect = apiResponse.isCorrect;
        livesRemaining = apiResponse.livesRemaining;
        canPlay = apiResponse.canPlay;
        nextRegenInSeconds = apiResponse.nextRegenInSeconds;
      } else {
        final response = await _quizRepository.submitAnswer(
          questionId: question.id,
          answer: jsonEncode(userAnswer.toJson()),
          context: <String, dynamic>{
            'questionText': question.content,
            'questionType': question.questionType.storageValue,
            'partNo': question.partNo,
            'difficultyLevel': question.difficultyLevel,
            'localEvaluation': evaluation.toJson(),
          },
        );
        submissionId = response.submissionId.isNotEmpty
            ? response.submissionId
            : response.answerId;
        responseIsCorrect = response.isCorrect;
      }

      if (submissionId.isEmpty) {
        throw Exception('Backend response missing submissionId/answerId.');
      }

      final isCorrect = evaluation.isCorrect || responseIsCorrect;

      if (isCorrect) {
        _wrongAnswersInRow = 0;
      } else {
        _wrongAnswersInRow += 1;
      }

      final highIdleDetected = _signalService.hasHighIdleTime();
      final wrongStreakDetected = _wrongAnswersInRow >= 3;

      if (highIdleDetected || wrongStreakDetected) {
        _moodStateService.setMood('Recovery');

        emit(
          QuizRecoveryTriggeredState(
            answer: visibleAnswer,
            submissionId: submissionId,
            wrongStreak: _wrongAnswersInRow,
            reason: highIdleDetected ? 'idle_time_high' : 'three_wrong_answers',
          ),
        );
        return;
      }

      emit(
        QuizSubmitSuccessState(
          submissionId: submissionId,
          answer: visibleAnswer,
          isCorrect: isCorrect,
          xpEarned: isCorrect ? (evaluation.score * 100).round() : 0,
          livesRemaining: livesRemaining,
          canPlay: canPlay,
          nextRegenInSeconds: nextRegenInSeconds,
        ),
      );
    } catch (e) {
      if (e is RateLimitException) {
        emit(
          QuizRateLimitedState(
            message:
                'Bạn đã vượt giới hạn phiên học hôm nay. Hãy nghỉ ngơi và quay lại ngày mai nhé!',
            answer: visibleAnswer,
          ),
        );
        return;
      }
      if (e is ForbiddenException) {
        final nextRegenInSeconds = _extractNextRegenInSeconds(e.details);
        emit(
          QuizNoLivesState(
            message: e.message.isNotEmpty
                ? e.message
                : 'Bạn đã hết tim! Hãy chờ hồi sinh hoặc xem lại bài cũ nhé.',
            answer: visibleAnswer,
            nextRegenInSeconds: nextRegenInSeconds,
          ),
        );
        return;
      }
      emit(
        QuizSubmitFailureState(
          message: 'Không thể gửi bài lúc này. Vui lòng thử lại.',
          answer: visibleAnswer,
        ),
      );
    }
  }

  Future<void> submitAllAnswers(
    List<Map<String, dynamic>> answerEntries,
  ) async {
    if (answerEntries.isEmpty) {
      emit(
        const QuizSubmitFailureState(
          message: 'Không có câu trả lời nào để gửi.',
          answer: '',
        ),
      );
      return;
    }

    emit(const QuizBatchSubmittingState(answer: ''));

    try {
      final response = await _quizRepository.submitBatchAnswers(
        answers: answerEntries,
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final total = data['totalSubmitted'] as int? ?? answerEntries.length;

      emit(QuizBatchSubmitSuccessState(totalSubmitted: total, answer: ''));
    } catch (_) {
      emit(
        const QuizSubmitFailureState(
          message: 'Không thể gửi toàn bộ bài. Vui lòng thử lại.',
          answer: '',
        ),
      );
    }
  }

  static bool _resolveIsCorrect(
    Map<String, dynamic> responseData,
    String submittedAnswer,
  ) {
    final fromPayload = responseData['isCorrect'];
    if (fromPayload is bool) {
      return fromPayload;
    }

    var normalized = submittedAnswer
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('*', '')
        .replaceAll('−', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');

    normalized = normalized.replaceAllMapped(
      RegExp(r"^((y'|y’|dy/dx|f\(x\)|f'\(x\)|y)=?)"),
      (_) => '',
    );

    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }

    const acceptedForms = <String>{
      '12x^2+4x',
      '4x+12x^2',
      '12x^2+4x+0',
      '4x+12x^2+0',
    };

    return acceptedForms.contains(normalized);
  }

  static String _visibleAnswer(QuizQuestionUserAnswer answer) {
    if (answer is MultipleChoiceUserAnswer) {
      return answer.selectedOptionId;
    }

    if (answer is ShortAnswerUserAnswer) {
      return answer.answerText;
    }

    if (answer is TrueFalseClusterUserAnswer) {
      if (answer.subAnswers.isEmpty) {
        return '';
      }

      final entries = answer.subAnswers.entries.toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key));

      return entries.map((item) => '${item.key}:${item.value}').join('|');
    }

    return '';
  }

  static int? _extractNextRegenInSeconds(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) {
      return null;
    }

    return _tryParseInt(details['next_regen_in_seconds']) ??
        _tryParseInt(details['nextRegenInSeconds']) ??
        _tryParseInt(details['next_regen_seconds']);
  }

  static int? _tryParseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
