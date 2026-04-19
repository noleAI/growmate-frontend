import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/core/network/rest_api_client.dart';
import 'package:growmate_frontend/features/quiz/data/repositories/quiz_api_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

RestApiClient _buildClient(http.Client httpClient) {
  return RestApiClient(
    httpClient: httpClient,
    getAccessToken: () async => 'token',
    getRefreshToken: () async => null,
    onTokenRefresh: (String accessToken, String refreshToken) async {},
  );
}

void main() {
  group('QuizApiRepository', () {
    test('getNextQuestion parses active backend payload', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/quiz/next'));
        expect(request.url.queryParameters['session_id'], 'sess-1');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'ok',
            'mode': 'exam_prep',
            'timer_sec': 45,
            'next_question': <String, dynamic>{
              'session_id': 'sess-1',
              'question_id': 'MATH_DERIV_1',
              'question_type': 'MULTIPLE_CHOICE',
              'content': 'Đạo hàm của x^2 là gì?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'A', 'text': '2x'},
                <String, dynamic>{'id': 'B', 'text': 'x'},
              ],
              'index': 0,
              'total_questions': 10,
              'progress_percent': 10,
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = QuizApiRepository(client: _buildClient(httpClient));
      final response = await repository.getNextQuestion(sessionId: 'sess-1');

      expect(response.status, 'ok');
      expect(response.sessionId, 'sess-1');
      expect(response.mode, 'exam_prep');
      expect(response.timerSec, 45);
      expect(response.nextQuestion, isNotNull);
      expect(response.nextQuestion!.questionId, 'MATH_DERIV_1');
      expect(response.nextQuestion!.options.first.id, 'A');
      expect(response.nextQuestion!.progressPercent, 10);
    });

    test('submitAnswer parses summary and lives fields', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/quiz/submit'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['session_id'], 'sess-2');
        expect(body['question_id'], 'MATH_DERIV_1');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'session_id': 'sess-2',
            'question_id': 'MATH_DERIV_1',
            'is_correct': true,
            'explanation': 'Vì (x^2)\' = 2x.',
            'score': 1,
            'max_score': 1,
            'progress_percent': 40,
            'last_question_index': 4,
            'total_questions': 10,
            'lives_remaining': 2,
            'can_play': true,
            'next_regen_in_seconds': 0,
            'quiz_summary': <String, dynamic>{
              'answered_count': 4,
              'correct_count': 3,
              'total_score': 3,
              'max_score': 4,
              'accuracy_percent': 75,
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = QuizApiRepository(client: _buildClient(httpClient));
      final response = await repository.submitAnswer(
        sessionId: 'sess-2',
        questionId: 'MATH_DERIV_1',
        selectedOption: 'A',
      );

      expect(response.sessionId, 'sess-2');
      expect(response.questionId, 'MATH_DERIV_1');
      expect(response.isCorrect, isTrue);
      expect(response.progressPercent, 40);
      expect(response.lastQuestionIndex, 4);
      expect(response.totalQuestions, 10);
      expect(response.livesRemaining, 2);
      expect(response.canPlay, isTrue);
      expect(response.quizSummary, isNotNull);
      expect(response.quizSummary!.accuracyPercent, 75);
    });

    test('getSessionResult parses attempts payload', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/quiz/sessions/sess-3/result'));

        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'ok',
            'session_id': 'sess-3',
            'session_status': 'completed',
            'progress_percent': 100,
            'last_question_index': 10,
            'total_questions': 10,
            'summary': <String, dynamic>{
              'answered_count': 10,
              'correct_count': 8,
              'total_score': 8,
              'max_score': 10,
              'accuracy_percent': 80,
            },
            'attempts': <Map<String, dynamic>>[
              <String, dynamic>{
                'question_id': 'MATH_DERIV_1',
                'question_template_id': 'template-1',
                'question_type': 'MULTIPLE_CHOICE',
                'is_correct': true,
                'score': 1,
                'max_score': 1,
                'explanation': 'ok',
                'user_answer': <String, dynamic>{'selected_option': 'A'},
                'submitted_at': '2026-04-19T12:00:00+00:00',
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = QuizApiRepository(client: _buildClient(httpClient));
      final response = await repository.getSessionResult(sessionId: 'sess-3');

      expect(response.status, 'ok');
      expect(response.sessionId, 'sess-3');
      expect(response.sessionStatus, 'completed');
      expect(response.summary.correctCount, 8);
      expect(response.attempts, hasLength(1));
      expect(response.attempts.single.questionId, 'MATH_DERIV_1');
    });

    test('getQuizHistory parses history entries', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/quiz/history'));

        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'ok',
            'total': 1,
            'limit': 20,
            'offset': 0,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'session_id': 'sess-4',
                'status': 'completed',
                'start_time': '2026-04-19T12:00:00+00:00',
                'end_time': '2026-04-19T12:10:00+00:00',
                'progress_percent': 100,
                'last_question_index': 10,
                'total_questions': 10,
                'summary': <String, dynamic>{
                  'answered_count': 10,
                  'correct_count': 9,
                  'total_score': 9,
                  'max_score': 10,
                  'accuracy_percent': 90,
                },
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = QuizApiRepository(client: _buildClient(httpClient));
      final response = await repository.getQuizHistory();

      expect(response.status, 'ok');
      expect(response.total, 1);
      expect(response.items, hasLength(1));
      expect(response.items.single.sessionId, 'sess-4');
      expect(response.items.single.summary.accuracyPercent, 90);
    });
  });
}
