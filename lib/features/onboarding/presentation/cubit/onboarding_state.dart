import '../../data/models/onboarding_models.dart';

sealed class OnboardingState {
  const OnboardingState();
}

/// Step 1 – Chào mừng (handled by OnboardingWelcomePage statically)
final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// Step 2 – Đang tải dữ liệu
final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Step 2 – Chọn mục tiêu
final class OnboardingGoalSelection extends OnboardingState {
  const OnboardingGoalSelection({
    required this.goals,
    this.selectedGoalId,
    required this.selectedDailyMinutes,
  });

  final List<StudyGoal> goals;
  final String? selectedGoalId;
  final int selectedDailyMinutes;

  OnboardingGoalSelection copyWith({
    String? selectedGoalId,
    int? selectedDailyMinutes,
  }) {
    return OnboardingGoalSelection(
      goals: goals,
      selectedGoalId: selectedGoalId ?? this.selectedGoalId,
      selectedDailyMinutes: selectedDailyMinutes ?? this.selectedDailyMinutes,
    );
  }
}

/// Step 3 – Quiz chẩn đoán đang diễn ra
final class OnboardingQuizInProgress extends OnboardingState {
  const OnboardingQuizInProgress({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.selectedGoalId,
    required this.dailyMinutes,
  });

  final List<OnboardingQuestion> questions;
  final int currentIndex;

  /// Map questionId → selectedOptionIndex
  final Map<String, int> answers;
  final String selectedGoalId;
  final int dailyMinutes;

  OnboardingQuestion get current => questions[currentIndex];
  bool get isLast => currentIndex == questions.length - 1;
  int get progress => currentIndex + 1;
  int get total => questions.length;

  OnboardingQuizInProgress copyWith({
    int? currentIndex,
    Map<String, int>? answers,
  }) {
    return OnboardingQuizInProgress(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      selectedGoalId: selectedGoalId,
      dailyMinutes: dailyMinutes,
    );
  }
}

/// Step 4 – Kết quả phân loại
final class OnboardingComplete extends OnboardingState {
  const OnboardingComplete({required this.result});

  final OnboardingResult result;
}

final class OnboardingError extends OnboardingState {
  const OnboardingError(this.message);
  final String message;
}
