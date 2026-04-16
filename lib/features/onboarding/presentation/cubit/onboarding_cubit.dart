import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/onboarding_models.dart';
import '../../data/repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required OnboardingRepository repository})
    : _repository = repository,
      super(const OnboardingInitial());

  final OnboardingRepository _repository;

  // Cached from quiz so completeOnboarding can submit to backend.
  List<OnboardingQuestion> _lastQuestions = const [];
  Map<String, int> _lastAnswers = const {};
  final Map<String, double> _timeTakenByQuestion = {};
  DateTime _questionShownAt = DateTime.now();

  // ── Step 2: Load goal selection ──────────────────────────────────────────

  Future<void> loadGoalSelection() async {
    emit(const OnboardingLoading());
    try {
      final goals = await _repository.getStudyGoals();
      emit(OnboardingGoalSelection(goals: goals));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  void selectGoal(String goalId) {
    final current = state;
    if (current is OnboardingGoalSelection) {
      emit(current.copyWith(selectedGoalId: goalId));
    }
  }

  // ── Step 3: Start quiz ────────────────────────────────────────────────────

  Future<void> startDiagnosticQuiz() async {
    final current = state;
    if (current is! OnboardingGoalSelection) return;
    final selectedGoalId = current.selectedGoalId;
    if (selectedGoalId == null) return;

    emit(const OnboardingLoading());
    try {
      final questions = await _repository.getDiagnosticQuestions();
      emit(
        OnboardingQuizInProgress(
          questions: questions,
          currentIndex: 0,
          answers: const {},
          selectedGoalId: selectedGoalId,
        ),
      );
      _questionShownAt = DateTime.now();
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  void answerQuestion(String questionId, int optionIndex) {
    final current = state;
    if (current is! OnboardingQuizInProgress) return;

    // Track time taken for this question.
    final elapsed = DateTime.now().difference(_questionShownAt);
    _timeTakenByQuestion[questionId] = elapsed.inMilliseconds / 1000.0;

    final newAnswers = Map<String, int>.from(current.answers)
      ..[questionId] = optionIndex;

    if (current.isLast) {
      // All questions answered → compute result
      _finishQuiz(current.copyWith(answers: newAnswers));
    } else {
      emit(
        current.copyWith(
          currentIndex: current.currentIndex + 1,
          answers: newAnswers,
        ),
      );
      _questionShownAt = DateTime.now();
    }
  }

  void _finishQuiz(OnboardingQuizInProgress state) {
    _lastQuestions = state.questions;
    _lastAnswers = Map<String, int>.from(state.answers);
    int correctCount = 0;
    for (final q in state.questions) {
      final userAnswer = state.answers[q.id];
      if (userAnswer != null && userAnswer == q.correctOptionIndex) {
        correctCount++;
      }
    }

    final level = _repository.classifyLevel(
      correctCount,
      state.questions.length,
    );

    final goal = state.selectedGoalId;
    emit(
      OnboardingComplete(
        result: OnboardingResult(
          level: level,
          correctCount: correctCount,
          totalQuestions: state.questions.length,
          elapsedMs: 0,
          selectedGoal: goal,
        ),
      ),
    );
  }

  // ── Step 4: Save & complete onboarding ───────────────────────────────────

  Future<void> completeOnboarding({String? userKey}) async {
    // Persist locally for fast guard checks.
    final prefs = await SharedPreferences.getInstance();
    final key = userKey != null ? 'isOnboarded_$userKey' : 'isOnboarded';
    await prefs.setBool(key, true);

    // Submit to backend so `onboarded_at` is stored server-side.
    final current = state;
    if (current is OnboardingComplete) {
      try {
        final response = await _repository.submitOnboarding(
          questions: _lastQuestions,
          answers: _lastAnswers,
          studyGoal: current.result.selectedGoal,
          timeTakenByQuestion: _timeTakenByQuestion,
        );
        // Persist backend-determined level and study plan for session creation.
        await prefs.setString('classification_level', response.userLevel.name);
        if (response.studyPlan != null) {
          await prefs.setString(
            'onboarding_study_plan',
            jsonEncode(response.studyPlan),
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ Backend onboarding submit failed (local flag saved): $e',
        );
      }
    }
  }
}
