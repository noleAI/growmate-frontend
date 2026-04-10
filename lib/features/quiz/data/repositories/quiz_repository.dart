import '../../../../core/network/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../offline/data/repositories/offline_mode_repository.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';

class QuizRepository {
  QuizRepository({
    required ApiService apiService,
    required this.sessionId,
    OfflineModeRepository? offlineModeRepository,
    SupabaseClient? supabaseClient,
  }) : _apiService = apiService,
       _offlineModeRepository =
           offlineModeRepository ?? OfflineModeRepository.instance,
       _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient();

  final ApiService _apiService;
  final String sessionId;
  final OfflineModeRepository _offlineModeRepository;
  final SupabaseClient? _supabaseClient;

  Future<List<QuizQuestionTemplate>> fetchQuestionTemplates({
    String subject = 'math',
    int examYear = 2026,
    int limit = 6,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      return const <QuizQuestionTemplate>[];
    }

    try {
      final rows = await client
          .from('quiz_question_template')
          .select()
          .eq('subject', subject)
          .eq('exam_year', examYear)
          .eq('is_active', true)
          .order('part_no', ascending: true)
          .order('difficulty_level', ascending: true)
          .limit(limit);

      return rows
          .whereType<Map>()
          .map(
            (item) =>
                QuizQuestionTemplate.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const <QuizQuestionTemplate>[];
    }
  }

  Future<void> recordEvaluatedAttempt({
    required QuizQuestionTemplate question,
    required QuizQuestionUserAnswer userAnswer,
    required QuizQuestionEvaluation evaluation,
  }) async {
    final client = _supabaseClient;
    final uid = client?.auth.currentUser?.id;

    if (client == null || uid == null || uid.isEmpty) {
      return;
    }

    if (!_isUuid(question.id)) {
      return;
    }

    final payload = <String, dynamic>{
      'student_id': uid,
      'question_template_id': question.id,
      'question_type': question.questionType.storageValue,
      'user_answer': userAnswer.toJson(),
      'evaluation': evaluation.toJson(),
      'score': evaluation.score,
      'max_score': evaluation.maxScore,
      'is_correct': evaluation.isCorrect,
    };

    if (_isUuid(sessionId)) {
      payload['session_id'] = sessionId;
    }

    try {
      await client.from('quiz_question_attempts').insert(payload);
    } catch (_) {
      // Preserve quiz flow when tracking write fails.
    }
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) {
    return _apiService.submitAnswer(
      sessionId: sessionId,
      questionId: questionId,
      answer: answer,
      context: context,
    );
  }

  Future<Map<String, dynamic>> submitSignals(
    List<Map<String, dynamic>> signals,
  ) async {
    final offlineEnabled = await _offlineModeRepository.isOfflineModeEnabled();

    if (offlineEnabled) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Offline mode is enabled, signals are queued locally.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }

    await _offlineModeRepository.flushQueuedSignals(
      submitter: (queuedSignals) {
        return _apiService.submitSignals(
          sessionId: sessionId,
          signals: queuedSignals,
        );
      },
    );

    try {
      return await _apiService.submitSignals(
        sessionId: sessionId,
        signals: signals,
      );
    } catch (_) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Network unstable, signals are queued for next sync.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
