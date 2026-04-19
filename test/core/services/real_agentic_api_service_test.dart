import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/core/services/real_agentic_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RealAgenticApiService', () {
    test(
      'createSession parses reused session metadata for resume flow',
      () async {
        final httpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, endsWith('/sessions'));

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['subject'], 'math');
          expect(body['topic'], 'derivatives');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'session_id': 'sess-existing',
              'status': 'active',
              'start_time': '2026-04-19T10:00:00+00:00',
              'reused_existing_session': true,
              'initial_state': <String, dynamic>{
                'mode': 'exam_prep',
                'progress_percent': 30,
                'last_question_index': 3,
              },
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        });

        final service = RealAgenticApiService(
          httpClient: httpClient,
          getAccessToken: () async => 'token',
          getRefreshToken: () async => null,
          onTokenRefresh: (String accessToken, String refreshToken) async {},
        );

        final response = await service.createSession(
          subject: 'math',
          topic: 'derivatives',
        );

        expect(response.sessionId, 'sess-existing');
        expect(response.reusedExistingSession, isTrue);
        expect(response.isResumed, isTrue);
        expect(response.progressPercent, 30);
        expect(response.lastQuestionIndex, 3);
        expect(response.mode, 'exam_prep');
      },
    );
  });
}
