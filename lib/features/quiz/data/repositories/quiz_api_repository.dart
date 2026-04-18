import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/network/rest_api_client.dart';
import '../models/quiz_api_models.dart';

/// Repository for backend quiz API endpoints.
///
/// Handles `GET /quiz/next` and `POST /quiz/submit` — the backend-driven
/// quiz flow (as opposed to direct Supabase table reads).
class QuizApiRepository {
  QuizApiRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  /// GET /api/v1/quiz/next
  Future<QuizNextResponse> getNextQuestion({
    required String sessionId,
    int index = 0,
    int totalQuestions = 10,
    String? mode,
  }) async {
    final params = <String, String>{
      'session_id': sessionId,
      'index': index.toString(),
      'total_questions': totalQuestions.toString(),
    };
    if (mode != null) params['mode'] = mode;

    final json = await _client.get('/quiz/next', queryParams: params);
    return QuizNextResponse.fromJson(json);
  }

  /// GET /api/v1/quiz/sessions/{session_id}/result
  Future<QuizSessionResultResponse> getSessionResult({
    required String sessionId,
  }) async {
    final encodedSessionId = Uri.encodeComponent(sessionId);
    final json = await _client.get('/quiz/sessions/$encodedSessionId/result');
    return QuizSessionResultResponse.fromJson(json);
  }

  /// GET /api/v1/quiz/history
  Future<QuizHistoryResponse> getQuizHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final json = await _client.get(
      '/quiz/history',
      queryParams: <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    return QuizHistoryResponse.fromJson(json);
  }

  /// POST /api/v1/quiz/submit
  ///
  /// Throws [RateLimitException] on 429 (daily session limit exceeded).
  Future<QuizSubmitResponse> submitAnswer({
    required String sessionId,
    required String questionId,
    String? selectedOption,
    String? answer,
    Map<String, dynamic>? answers,
    double? timeTakenSec,
    String? mode,
    int? questionIndex,
    int? totalQuestions,
  }) async {
    final body = <String, dynamic>{
      'session_id': sessionId,
      'question_id': questionId,
    };
    if (selectedOption != null) body['selected_option'] = selectedOption;
    if (answer != null) body['answer'] = answer;
    if (answers != null) body['answers'] = answers;
    if (timeTakenSec != null) body['time_taken_sec'] = timeTakenSec;
    if (mode != null) body['mode'] = mode;
    if (questionIndex != null) body['question_index'] = questionIndex;
    if (totalQuestions != null) body['total_questions'] = totalQuestions;

    try {
      final json = await _client.post('/quiz/submit', body);
      return QuizSubmitResponse.fromJson(json);
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('QuizApiRepository.submitAnswer error: $e');
      rethrow;
    }
  }
}
