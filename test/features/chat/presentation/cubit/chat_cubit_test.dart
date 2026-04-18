import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/core/error/app_exceptions.dart';
import 'dart:typed_data';
import 'package:growmate_frontend/features/chat/data/repositories/chat_repository.dart';
import 'package:growmate_frontend/features/chat/domain/entities/chat_message.dart';
import 'package:growmate_frontend/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:growmate_frontend/features/chat/presentation/cubit/chat_state.dart';

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({this.history = const [], this.sendError});

  final List<ChatMessage> history;
  final Object? sendError;

  bool clearWasCalled = false;

  @override
  void clearHistory() {
    clearWasCalled = true;
  }

  @override
  ChatMessage getGreeting() {
    return ChatMessage(
      id: 'greeting_0',
      role: ChatRole.assistant,
      content: 'hello',
      timestamp: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<List<ChatMessage>> loadHistory({int limit = 40}) async {
    return history;
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    return ChatMessage(
      id: 'ai_img_1',
      role: ChatRole.assistant,
      content: 'Image received',
      timestamp: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<ChatSendResult> sendMessage(
    String userMessage, {
    List<ChatMessage> history = const [],
  }) async {
    if (sendError != null) {
      throw sendError!;
    }

    return ChatSendResult(
      reply: ChatMessage(
        id: 'ai_1',
        role: ChatRole.assistant,
        content: 'ok',
        timestamp: DateTime(2026, 1, 1),
      ),
    );
  }
}

void main() {
  group('ChatCubit', () {
    test('initialize uses server history when available', () async {
      final repository = _FakeChatRepository(
        history: [
          ChatMessage(
            id: 'history_1',
            role: ChatRole.user,
            content: 'Hi',
            timestamp: DateTime(2026, 1, 1),
          ),
          ChatMessage(
            id: 'history_2',
            role: ChatRole.assistant,
            content: 'Hello',
            timestamp: DateTime(2026, 1, 1),
          ),
        ],
      );

      final cubit = ChatCubit(repository: repository);
      await cubit.initialize();

      final state = cubit.state;
      expect(state, isA<ChatReady>());
      expect((state as ChatReady).messages.length, 2);

      await cubit.close();
    });

    test('returns quotaExceeded and appends friendly message on 429', () async {
      final repository = _FakeChatRepository(
        sendError: const RateLimitException(
          message: 'quota exceeded',
          details: {'limit': 30, 'used': 30},
        ),
      );

      final cubit = ChatCubit(repository: repository);
      await cubit.initialize();

      final outcome = await cubit.sendMessage('Need help');
      expect(outcome, ChatSendOutcome.quotaExceeded);

      final state = cubit.state;
      expect(state, isA<ChatReady>());
      final ready = state as ChatReady;
      expect(ready.messages.last.role, ChatRole.assistant);
      expect(ready.messages.last.content, contains('hết lượt chat hôm nay'));

      await cubit.close();
    });

    test('clearChat resets to greeting message', () async {
      final repository = _FakeChatRepository();
      final cubit = ChatCubit(repository: repository);

      await cubit.initialize();
      cubit.clearChat();

      final state = cubit.state;
      expect(state, isA<ChatReady>());
      expect((state as ChatReady).messages.single.id, 'greeting_0');
      expect(repository.clearWasCalled, isTrue);

      await cubit.close();
    });
  });
}
