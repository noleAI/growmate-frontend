import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/api_models.dart';
import '../../data/repositories/quiz_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc({
    required QuizRepository quizRepository,
    required this.questionId,
    required this.questionText,
  }) : _quizRepository = quizRepository,
       super(const QuizInitial()) {
    on<QuizStarted>(_onQuizStarted);
    on<AnswerChanged>(_onAnswerChanged);
    on<QuizSubmitted>(_onQuizSubmitted);
  }

  final QuizRepository _quizRepository;
  final String questionId;
  final String questionText;

  void _onQuizStarted(QuizStarted event, Emitter<QuizState> emit) {
    emit(const QuizInitial());
  }

  void _onAnswerChanged(AnswerChanged event, Emitter<QuizState> emit) {
    if (state is QuizLoading) {
      return;
    }

    emit(QuizInitial(answer: event.answer));
  }

  Future<void> _onQuizSubmitted(
    QuizSubmitted event,
    Emitter<QuizState> emit,
  ) async {
    final trimmedAnswer = event.answer.trim();

    if (trimmedAnswer.isEmpty) {
      emit(
        QuizFailure(
          message: 'Vui lòng nhập kết quả trước khi gửi.',
          answer: event.answer,
        ),
      );
      return;
    }

    emit(QuizLoading(answer: event.answer));

    try {
      final response = await _quizRepository.submitAnswer(
        questionId: questionId,
        answer: trimmedAnswer,
        context: <String, dynamic>{'questionText': questionText},
      );

      final responseData = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final submitResponse = SubmitAnswerResponse.fromJson(responseData);

      final submissionId = submitResponse.submissionId.isNotEmpty
          ? submitResponse.submissionId
          : submitResponse.answerId;

      if (submissionId.isEmpty) {
        throw Exception('Backend response missing submissionId/answerId.');
      }

      emit(QuizSuccess(submissionId: submissionId, answer: event.answer));
    } catch (_) {
      emit(
        QuizFailure(
          message: 'Không thể gửi bài lúc này. Vui lòng thử lại.',
          answer: event.answer,
        ),
      );
    }
  }
}
