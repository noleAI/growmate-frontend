import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../core/services/mood_state_service.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';
import '../../data/repositories/quiz_repository.dart';

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
  });

  final String submissionId;

  @override
  List<Object?> get props => <Object?>[...super.props, submissionId];
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

class QuizCubit extends Cubit<QuizCubitState> {
  QuizCubit({
    required QuizRepository quizRepository,
    required this.questionId,
    required this.questionText,
    BehavioralSignalService? signalService,
    MoodStateService? moodStateService,
  }) : _quizRepository = quizRepository,
       _signalService = signalService ?? BehavioralSignalService.instance,
       _moodStateService = moodStateService ?? MoodStateService.instance,
       super(const QuizIdleState());

  static int _wrongAnswersInRow = 0;

  final QuizRepository _quizRepository;
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
      final response = await _quizRepository.submitAnswer(
        questionId: questionId,
        answer: trimmedAnswer,
        context: <String, dynamic>{'questionText': questionText},
      );

      final responseData = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final submissionId =
          responseData['submissionId']?.toString() ??
          responseData['answerId']?.toString() ??
          '';

      if (submissionId.isEmpty) {
        throw Exception('Backend response missing submissionId/answerId.');
      }

      final isCorrect = _resolveIsCorrect(responseData, trimmedAnswer);
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

      emit(QuizSubmitSuccessState(submissionId: submissionId, answer: answer));
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

      final responseData = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final submissionId =
          responseData['submissionId']?.toString() ??
          responseData['answerId']?.toString() ??
          '';

      if (submissionId.isEmpty) {
        throw Exception('Backend response missing submissionId/answerId.');
      }

      final responseIsCorrect = responseData['isCorrect'] == true;
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
        ),
      );
    } catch (_) {
      emit(
        QuizSubmitFailureState(
          message: 'Không thể gửi bài lúc này. Vui lòng thử lại.',
          answer: visibleAnswer,
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
}
