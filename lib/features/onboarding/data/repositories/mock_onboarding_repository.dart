import '../mock/mock_onboarding_data.dart';
import '../models/onboarding_models.dart';
import '../models/onboarding_submit_response.dart';
import '../models/user_level.dart';
import 'onboarding_repository.dart';

class MockOnboardingRepository implements OnboardingRepository {
  @override
  Future<List<OnboardingQuestion>> getDiagnosticQuestions() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return mockOnboardingQuestions;
  }

  @override
  Future<List<StudyGoal>> getStudyGoals() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return mockStudyGoals;
  }

  @override
  UserLevel classifyLevel(int correctCount, int totalQuestions) {
    if (totalQuestions == 0) return UserLevel.beginner;
    final accuracy = correctCount / totalQuestions;
    if (accuracy < 0.4) return UserLevel.beginner;
    if (accuracy < 0.7) return UserLevel.intermediate;
    return UserLevel.advanced;
  }

  @override
  Future<OnboardingSubmitResponse> submitOnboarding({
    required List<OnboardingQuestion> questions,
    required Map<String, int> answers,
    required String studyGoal,
    int? dailyMinutes,
    Map<String, double>? timeTakenByQuestion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Grade locally using correctOptionIndex
    int correctCount = 0;
    for (final q in questions) {
      final userAnswer = answers[q.id];
      if (userAnswer != null && userAnswer == q.correctOptionIndex) {
        correctCount++;
      }
    }
    final level = classifyLevel(correctCount, questions.length);
    final accuracy = questions.isEmpty
        ? 0.0
        : (correctCount / questions.length) * 100;
    return OnboardingSubmitResponse(
      userLevel: level,
      accuracyPercent: accuracy,
      message: 'Kết quả chẩn đoán: ${level.viLabel}',
    );
  }
}
