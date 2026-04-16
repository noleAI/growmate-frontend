import '../../../../core/network/rest_api_client.dart';
import '../models/onboarding_models.dart';
import '../models/onboarding_submit_response.dart';
import '../models/user_level.dart';
import 'onboarding_repository.dart';

/// Real implementation calling the backend REST API.
class RealOnboardingRepository implements OnboardingRepository {
  RealOnboardingRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  @override
  Future<List<OnboardingQuestion>> getDiagnosticQuestions() async {
    final json = await _client.get('/onboarding/questions');
    final rawQuestions = json['questions'];
    if (rawQuestions is! List) return const [];
    return rawQuestions
        .whereType<Map<String, dynamic>>()
        .map((q) {
          final rawOptions = q['options'];
          final options = <OnboardingOption>[];
          if (rawOptions is List) {
            for (final o in rawOptions) {
              if (o is Map) {
                options.add(
                  OnboardingOption(
                    id: (o['id'] ?? '').toString(),
                    text: (o['text'] ?? '').toString(),
                  ),
                );
              } else {
                options.add(
                  OnboardingOption(id: o.toString(), text: o.toString()),
                );
              }
            }
          }
          return OnboardingQuestion(
            id: (q['id'] ?? q['question_id'] ?? '').toString(),
            questionText: (q['content'] ?? '').toString(),
            options: options,
            // Backend grades server-side; correctOptionIndex unknown client-side
            correctOptionIndex: -1,
            topicTag: q['related_hypothesis']?.toString(),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<StudyGoal>> getStudyGoals() async {
    // Backend doesn't expose study goals endpoint — use local data.
    return const [
      StudyGoal(
        id: 'exam_prep',
        label: 'Ôn thi THPT',
        emoji: '🎯',
        description: 'Tập trung luyện đề và nắm chắc kiến thức thi',
      ),
      StudyGoal(
        id: 'explore',
        label: 'Khám phá kiến thức',
        emoji: '🌱',
        description: 'Học theo sở thích, không áp lực thời gian',
      ),
    ];
  }

  @override
  UserLevel classifyLevel(int correctCount, int totalQuestions) {
    // Local fallback — primary classification via submitOnboarding.
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
    // Map answers from index → option ID (e.g. "A", "B")
    final answerList = <Map<String, dynamic>>[];
    for (final entry in answers.entries) {
      final question = questions.firstWhere(
        (q) => q.id == entry.key,
        orElse: () => OnboardingQuestion(
          id: entry.key,
          questionText: '',
          options: const [],
          correctOptionIndex: -1,
        ),
      );
      final selectedId =
          entry.value >= 0 && entry.value < question.options.length
          ? question.options[entry.value].id
          : '';
      answerList.add({
        'question_id': entry.key,
        'selected': selectedId,
        if (timeTakenByQuestion != null &&
            timeTakenByQuestion.containsKey(entry.key))
          'time_taken_sec': timeTakenByQuestion[entry.key],
      });
    }

    final body = <String, dynamic>{
      'answers': answerList,
      'study_goal': studyGoal,
    };
    if (dailyMinutes != null) {
      body['daily_minutes'] = dailyMinutes;
    }

    final json = await _client.post('/onboarding/submit', body);
    return OnboardingSubmitResponse.fromJson(json);
  }
}
