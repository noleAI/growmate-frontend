import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/core/network/rest_api_client.dart';
import 'package:growmate_frontend/features/session_recovery/data/repositories/session_recovery_repository.dart';
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
  group('SessionRecoveryRepository', () {
    test('getPendingSession parses sessions pending payload', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/sessions/pending'));

        return http.Response(
          jsonEncode(<String, dynamic>{
            'has_pending': true,
            'session': <String, dynamic>{
              'session_id': 'sess-1',
              'status': 'active',
              'last_question_index': 4,
              'next_question_index': 4,
              'total_questions': 10,
              'progress_percent': 40,
              'mode': 'exam_prep',
              'pause_state': false,
              'resume_context_version': 1,
              'last_active_at': '2026-04-19T11:30:00+00:00',
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = SessionRecoveryRepository(
        client: _buildClient(httpClient),
      );
      final response = await repository.getPendingSession();

      expect(response.hasPending, isTrue);
      expect(response.sessionId, 'sess-1');
      expect(response.lastQuestionIndex, 4);
      expect(response.nextQuestionIndex, 4);
      expect(response.totalQuestions, 10);
      expect(response.progressPercent, 40);
      expect(response.mode, 'exam_prep');
    });
  });
}
