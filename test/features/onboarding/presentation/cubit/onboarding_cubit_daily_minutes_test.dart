import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growmate_frontend/features/onboarding/data/models/onboarding_models.dart';
import 'package:growmate_frontend/features/onboarding/data/models/onboarding_submit_response.dart';
import 'package:growmate_frontend/features/onboarding/data/models/user_level.dart';
import 'package:growmate_frontend/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:growmate_frontend/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:growmate_frontend/features/onboarding/presentation/cubit/onboarding_state.dart';

class _FakeOnboardingRepository implements OnboardingRepository {
  int? submittedDailyMinutes;
  String? submittedStudyGoal;

  @override
  UserLevel classifyLevel(int correctCount, int totalQuestions) {
    return UserLevel.intermediate;
  }

  @override
  Future<List<OnboardingQuestion>> getDiagnosticQuestions() async {
    return const [
      OnboardingQuestion(
        id: 'q_1',
        questionText: 'Question',
        options: [
          OnboardingOption(id: 'A', text: 'A'),
          OnboardingOption(id: 'B', text: 'B'),
        ],
        correctOptionIndex: 0,
      ),
    ];
  }

  @override
  Future<List<StudyGoal>> getStudyGoals() async {
    return const [
      StudyGoal(
        id: 'exam_prep',
        label: 'Exam prep',
        emoji: '🎯',
        description: 'Goal',
      ),
      StudyGoal(
        id: 'explore',
        label: 'Explore',
        emoji: '🌱',
        description: 'Goal',
      ),
    ];
  }

  @override
  Future<OnboardingSubmitResponse> submitOnboarding({
    required List<OnboardingQuestion> questions,
    required Map<String, int> answers,
    required String studyGoal,
    int? dailyMinutes,
    Map<String, double>? timeTakenByQuestion,
  }) async {
    submittedStudyGoal = studyGoal;
    submittedDailyMinutes = dailyMinutes;

    return OnboardingSubmitResponse(
      userLevel: UserLevel.intermediate,
      accuracyPercent: 100,
      message: 'ok',
      studyPlan: {'daily_minutes': dailyMinutes},
    );
  }
}

void main() {
  group('OnboardingCubit daily minutes', () {
    test('loads cached daily minutes into goal selection state', () async {
      SharedPreferences.setMockInitialValues({'daily_minutes': 45});

      final repo = _FakeOnboardingRepository();
      final cubit = OnboardingCubit(repository: repo);

      await cubit.loadGoalSelection();

      final state = cubit.state;
      expect(state, isA<OnboardingGoalSelection>());
      expect((state as OnboardingGoalSelection).selectedDailyMinutes, 45);

      await cubit.close();
    });

    test('submits and persists selected daily minutes on completion', () async {
      SharedPreferences.setMockInitialValues({});

      final repo = _FakeOnboardingRepository();
      final cubit = OnboardingCubit(repository: repo);

      await cubit.loadGoalSelection();
      cubit.selectGoal('exam_prep');
      cubit.selectDailyMinutes(35);

      await cubit.startDiagnosticQuiz();
      final quizState = cubit.state;
      expect(quizState, isA<OnboardingQuizInProgress>());
      expect((quizState as OnboardingQuizInProgress).dailyMinutes, 35);

      cubit.answerQuestion('q_1', 0);
      final completeState = cubit.state;
      expect(completeState, isA<OnboardingComplete>());
      expect((completeState as OnboardingComplete).result.dailyMinutes, 35);

      await cubit.completeOnboarding(userKey: 'user@example.com');

      expect(repo.submittedStudyGoal, 'exam_prep');
      expect(repo.submittedDailyMinutes, 35);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isOnboarded_user@example.com'), isTrue);
      expect(prefs.getString('study_goal'), 'exam_prep');
      expect(prefs.getInt('daily_minutes'), 35);

      await cubit.close();
    });
  });
}
