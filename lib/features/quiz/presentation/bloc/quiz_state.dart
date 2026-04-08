import 'package:equatable/equatable.dart';

sealed class QuizState extends Equatable {
  const QuizState({required this.answer});

  final String answer;

  @override
  List<Object?> get props => <Object?>[answer];
}

final class QuizInitial extends QuizState {
  const QuizInitial({super.answer = ''});
}

final class QuizLoading extends QuizState {
  const QuizLoading({required super.answer});
}

final class QuizSuccess extends QuizState {
  const QuizSuccess({required this.submissionId, required super.answer});

  final String submissionId;

  @override
  List<Object?> get props => <Object?>[...super.props, submissionId];
}

final class QuizFailure extends QuizState {
  const QuizFailure({required this.message, required super.answer});

  final String message;

  @override
  List<Object?> get props => <Object?>[...super.props, message];
}
