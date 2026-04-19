import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/core/network/rest_api_client.dart';
import 'package:growmate_frontend/features/chat/data/repositories/real_chat_repository.dart';
import 'package:growmate_frontend/features/chat/domain/entities/chat_message.dart';
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
  group('RealChatRepository', () {
    test('sendMessage parses backend reply and processing metadata', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/chatbot/chat'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['message'], 'Xin chào');
        expect(body['history'], isA<List<dynamic>>());

        return http.Response(
          jsonEncode(<String, dynamic>{
            'reply': 'Chào bạn, mình có thể giúp gì?',
            'remaining_quota': 29,
            'processing': <String, dynamic>{
              'summary': 'Đã dùng lịch sử chat gần đây để soạn câu trả lời.',
              'tags': <String>['Lịch sử chat', '2 lượt ngữ cảnh'],
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = RealChatRepository(client: _buildClient(httpClient));
      final result = await repository.sendMessage(
        'Xin chào',
        history: <ChatMessage>[
          ChatMessage(
            id: 'u1',
            role: ChatRole.user,
            content: 'Hello',
            timestamp: DateTime(2026, 4, 19, 10),
          ),
          ChatMessage(
            id: 'a1',
            role: ChatRole.assistant,
            content: 'Hi',
            timestamp: DateTime(2026, 4, 19, 10, 0, 1),
          ),
        ],
      );

      expect(result.remainingQuota, 29);
      expect(result.reply.content, 'Chào bạn, mình có thể giúp gì?');
      expect(
        result.reply.processingSummary,
        'Đã dùng lịch sử chat gần đây để soạn câu trả lời.',
      );
      expect(result.reply.processingTags, <String>[
        'Lịch sử chat',
        '2 lượt ngữ cảnh',
      ]);
    });

    test('loadHistory parses image attachment payload from backend', () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/chatbot/history'));

        return http.Response(
          jsonEncode(<String, dynamic>{
            'messages': <Map<String, dynamic>>[
              <String, dynamic>{
                'role': 'assistant',
                'content': 'Đây là ảnh minh họa.',
                'created_at': '2026-04-19T11:00:00+00:00',
                'attachment': <String, dynamic>{
                  'type': 'image',
                  'mime_type': 'image/png',
                  'file_name': 'example.png',
                  'url': 'https://example.com/example.png',
                },
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final repository = RealChatRepository(client: _buildClient(httpClient));
      final history = await repository.loadHistory();

      expect(history, hasLength(1));
      expect(history.single.role, ChatRole.assistant);
      expect(history.single.content, 'Đây là ảnh minh họa.');
      expect(history.single.imageUrl, 'https://example.com/example.png');
      expect(history.single.imageMimeType, 'image/png');
      expect(history.single.imageName, 'example.png');
      expect(history.single.processingSummary, isNull);
      expect(history.single.processingTags, isEmpty);
    });
  });
}
