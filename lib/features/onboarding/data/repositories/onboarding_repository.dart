import '../models/onboarding_models.dart';
import '../models/onboarding_submit_response.dart';
import '../models/user_level.dart';

abstract class OnboardingRepository {
  Future<List<OnboardingQuestion>> getDiagnosticQuestions();
  Future<List<StudyGoal>> getStudyGoals();

  /// Phân loại trình độ dựa trên số câu đúng và tổng thời gian (ms).
  UserLevel classifyLevel(int correctCount, int totalQuestions);

  /// Gửi kết quả onboarding lên backend để chấm điểm và phân loại.
  Future<OnboardingSubmitResponse> submitOnboarding({
    required List<OnboardingQuestion> questions,
    required Map<String, int> answers,
    required String studyGoal,
    int? dailyMinutes,
    Map<String, double>? timeTakenByQuestion,
  });
}
