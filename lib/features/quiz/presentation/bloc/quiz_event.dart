import 'package:equatable/equatable.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class QuizStarted extends QuizEvent {
  const QuizStarted();
}

final class AnswerChanged extends QuizEvent {
  const AnswerChanged(this.answer);

  final String answer;

  @override
  List<Object?> get props => <Object?>[answer];
}

final class QuizSubmitted extends QuizEvent {
  const QuizSubmitted({required this.answer});

  final String answer;

  @override
  List<Object?> get props => <Object?>[answer];
}
