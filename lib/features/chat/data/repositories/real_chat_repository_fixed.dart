import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/network/agentic_api_service.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

/// Real chat repository using chatbot endpoints.
///
/// Improved version with comprehensive error handling and multiple field name support.
class RealChatRepository implements ChatRepository {
  RealChatRepository({
    required RestApiClient client,
    AgenticApiService? legacyApiService,
    String? legacySessionId,
  }) : _client = client,
       _legacyApiService = legacyApiService,
       _legacySessionId = legacySessionId;

  final RestApiClient _client;
  final AgenticApiService? _legacyApiService;
  final String? _legacySessionId;

  @override
  Future<ChatSendResult> sendMessage(
    String userMessage, {
    List<ChatMessage> history = const [],
  }) async {
    final payload = <String, dynamic>{'message': userMessage};
    final historyTurns = _toHistoryPayload(history);
    if (historyTurns.isNotEmpty) {
      payload['history'] = historyTurns;
    }

    try {
      final json = await _client.post('/chatbot/chat', payload);
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Raw API response: $json');
      }

      final data = _unwrapPayload(json);
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Unwrapped data: $data');
      }

      // Try multiple field names for reply (backend might use different names)
      final replyText = _extractTextField(data, [
        'reply',
        'content',
        'message',
        'text',
        'response',
        'answer',
      ]);

      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Extracted reply: "$replyText"');
      }

      // Try multiple field names for remaining quota
      final remainingQuota = _toInt(
        data['remaining_quota'] ??
            data['remainingQuota'] ??
            data['quota'] ??
            data['quotaRemaining'] ??
            data['remaining'] ??
            data['left'],
      );

      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Remaining quota: $remainingQuota');
      }

      return ChatSendResult(
        reply: ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: replyText?.isNotEmpty == true
              ? replyText!
              : 'Mình chưa nhận được phản hồi hợp lệ từ server. Bạn thử lại giúp mình nhé!',
          timestamp: DateTime.now(),
        ),
        remainingQuota: remainingQuota,
      );
    } on AppException catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] AppException (${e.statusCode}): ${e.message}');
      }
      if (e.statusCode == 404) {
        return _sendViaLegacyInteract(userMessage);
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Unexpected error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<ChatMessage>> loadHistory({int limit = 40}) async {
    try {
      final json = await _client.get(
        '/chatbot/history',
        queryParams: {'limit': '$limit'},
      );
      final data = _unwrapPayload(json);
      final rawMessages = data['messages'];
      if (rawMessages is! List) {
        return const [];
      }

      final messages = <ChatMessage>[];
      for (final item in rawMessages) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final role = _parseRole(map['role']?.toString());
        if (role == null) continue;

        final content = map['content']?.toString().trim() ?? '';
        if (content.isEmpty) continue;

        final createdAt = DateTime.tryParse(
          map['created_at']?.toString() ?? '',
        );

        messages.add(
          ChatMessage(
            id: 'history_${messages.length}_${DateTime.now().microsecondsSinceEpoch}',
            role: role,
            content: content,
            timestamp: (createdAt ?? DateTime.now()).toLocal(),
          ),
        );
      }

      return messages;
    } on AppException catch (e) {
      if (e.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  ChatMessage getGreeting() {
    return ChatMessage(
      id: 'greeting_0',
      role: ChatRole.assistant,
      content:
          'Xin chào! Mình là GrowMate AI 🤖\n\n'
          'Mình có thể giúp bạn:\n'
          '• Giải thích bài tập Toán (đạo hàm, tích phân, logarit...)\n'
          '• Ôn tập kiến thức THPT 2026\n'
          '• Gợi ý phương pháp học hiệu quả\n'
          '• Giải đề thi thử\n\n'
          'Hỏi mình bất cứ điều gì nhé! 📚',
      timestamp: DateTime.now(),
    );
  }

  @override
  void clearHistory() {
    // Real chat history is server-side; nothing to clear locally.
  }

  Future<ChatSendResult> _sendViaLegacyInteract(String userMessage) async {
    final legacyApiService = _legacyApiService;
    final legacySessionId = _legacySessionId;
    if (legacyApiService == null || legacySessionId == null) {
      throw const NotFoundException(
        resource: 'chatbot',
        message: 'Không tìm thấy chatbot endpoint phù hợp.',
      );
    }

    final response = await legacyApiService.interact(
      sessionId: legacySessionId,
      actionType: 'chat',
      responseData: {'message': userMessage},
    );

    return ChatSendResult(
      reply: ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: response.content,
        timestamp: DateTime.now(),
        planRepaired: response.planRepaired,
        beliefEntropy: response.beliefEntropy,
        nextNodeType: response.nextNodeType,
      ),
    );
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return json;
  }

  /// Extract text from first non-empty field matching any of the given keys.
  String? _extractTextField(
    Map<String, dynamic> data,
    List<String> fieldNames,
  ) {
    for (final field in fieldNames) {
      final value = data[field]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🤖 [CHAT] Found reply in field: "$field"');
        }
        return value;
      }
    }
    if (kDebugMode) {
      debugPrint('🤖 [CHAT] No reply found in fields: $fieldNames');
    }
    return null;
  }

  List<Map<String, String>> _toHistoryPayload(List<ChatMessage> history) {
    final turns = <Map<String, String>>[];
    for (final message in history) {
      if (message.id.startsWith('greeting_')) {
        continue;
      }

      final role = switch (message.role) {
        ChatRole.user => 'user',
        ChatRole.assistant => 'assistant',
        ChatRole.system => null,
      };
      if (role == null) {
        continue;
      }

      final content = message.content.trim();
      if (content.isEmpty) {
        continue;
      }

      turns.add({'role': role, 'content': content});
    }

    if (turns.length <= 20) {
      return turns;
    }
    return turns.sublist(turns.length - 20);
  }

  ChatRole? _parseRole(String? rawRole) {
    return switch (rawRole?.toLowerCase()) {
      'user' => ChatRole.user,
      'assistant' => ChatRole.assistant,
      _ => null,
    };
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
