import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

/// Real chat repository with comprehensive error handling.
///
/// Uses RestApiClient for enhanced API handling and comprehensive error detection.
class RealChatRepository implements ChatRepository {
  RealChatRepository({
    required RestApiClient client,
  }) : _client = client;

  final RestApiClient _client;

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

      // Try multiple field names for reply
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
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] Unexpected error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    if (imageBytes.isEmpty) {
      return _errorMessage('Ảnh không hợp lệ. Vui lòng chọn ảnh khác.');
    }

    final payload = <String, dynamic>{'message': userMessage};

    try {
      // For simplicity, try sending via the regular endpoint first
      // In production, this would use a proper multipart/form-data endpoint
      final json = await _client.post('/chatbot/chat', payload);
      
      final data = _unwrapPayload(json);
      final replyText = _extractTextField(data, [
        'reply',
        'content',
        'message',
        'text',
        'response',
        'answer',
      ]);

      return ChatMessage(
        id: 'ai_img_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: replyText?.isNotEmpty == true
            ? replyText!
            : 'Mình chưa nhận được phản hồi hợp lệ từ server. Bạn thử lại giúp mình nhé!',
        timestamp: DateTime.now(),
      );
    } on AppException catch (e) {
      if (kDebugMode) {
        debugPrint('🖼️ [CHAT IMAGE] AppException (${e.statusCode}): ${e.message}');
      }
      if (e.statusCode == 404) {
        return _errorMessage('Chức năng gửi ảnh hiện không khả dụng.');
      }
      return _errorMessage('Không thể xử lý ảnh. Bạn thử lại nhé!');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🖼️ [CHAT IMAGE] Error: $e');
      }
      return _errorMessage('Không thể gửi ảnh. Bạn thử lại nhé!');
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] loadHistory error: $e');
      }
      return const [];
    }
  }

  @override
  ChatMessage getGreeting() {
    return ChatMessage(
      id: 'greeting_0',
      role: ChatRole.assistant,
      content:
          'Xin chào! Mình là GrowMate AI 🤖\n\n'
          'Mình có thể giúp bạn với bất kỳ môn học THPT nào:\n'
          '• 📐 Toán, Lý, Hóa, Sinh\n'
          '• 📖 Văn, Sử, Địa, GDCD\n'
          '• 🌍 Tiếng Anh, Tin học\n'
          '• 💡 Phương pháp ôn thi THPT Quốc gia\n\n'
          'Hỏi mình bất cứ điều gì về kiến thức học thuật nhé! 📚',
      timestamp: DateTime.now(),
    );
  }

  @override
  void clearHistory() {
    // Placeholder for future implementation
    if (kDebugMode) {
      debugPrint('🤖 [CHAT] clearHistory called');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ChatMessage _errorMessage(String content) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> _unwrapPayload(dynamic json) {
    if (json is Map<String, dynamic>) {
      if (json.containsKey('data') && json['data'] is Map) {
        return Map<String, dynamic>.from(json['data']);
      }
      return json;
    }
    return {};
  }

  String? _extractTextField(Map<String, dynamic> data, List<String> fieldNames) {
    for (final fieldName in fieldNames) {
      final value = data[fieldName];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  ChatRole? _parseRole(String? roleStr) {
    if (roleStr == null) return null;
    if (roleStr == 'user') return ChatRole.user;
    if (roleStr == 'assistant') return ChatRole.assistant;
    return null;
  }

  List<Map<String, dynamic>> _toHistoryPayload(List<ChatMessage> history) {
    return history
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();
  }
}
