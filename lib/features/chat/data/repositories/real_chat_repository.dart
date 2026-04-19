import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../../quota/data/models/quota_status.dart';
import 'chat_repository.dart';

/// Real chat repository with comprehensive error handling.
///
/// Uses RestApiClient for enhanced API handling and comprehensive error detection.
class RealChatRepository implements ChatRepository {
  RealChatRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  @override
  Future<QuotaStatus> fetchQuota() async {
    try {
      final json = await _client.get('/chatbot/quota');
      return QuotaStatus.fromJson(_unwrapPayload(json));
    } on AppException catch (e) {
      if (e.statusCode == 404) {
        return QuotaStatus.defaultQuota;
      }
      rethrow;
    }
  }

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
          nextNodeType: data['next_node_type']?.toString(),
          planRepaired: _toBool(data['plan_repaired']),
          beliefEntropy: _toDouble(data['belief_entropy']),
          processingSummary: _processingSummary(data['processing']),
          processingTags: _processingTags(data['processing']),
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
  Future<ChatSendResult> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    if (imageBytes.isEmpty) {
      return ChatSendResult(
        reply: _errorMessage('Ảnh không hợp lệ. Vui lòng chọn ảnh khác.'),
      );
    }

    try {
      final json = await _client.postMultipart(
        '/chatbot/chat/image',
        fields: {'message': userMessage},
        fileField: 'image',
        fileBytes: imageBytes,
        filename: imageName,
        mimeType: imageMimeType,
      );

      final data = _unwrapPayload(json);
      final replyText = _extractTextField(data, [
        'reply',
        'content',
        'message',
        'text',
        'response',
        'answer',
      ]);
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
          id: 'ai_img_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: replyText?.isNotEmpty == true
              ? replyText!
              : 'Mình chưa nhận được phản hồi hợp lệ từ server. Bạn thử lại giúp mình nhé!',
          timestamp: DateTime.now(),
          nextNodeType: data['next_node_type']?.toString(),
          planRepaired: _toBool(data['plan_repaired']),
          beliefEntropy: _toDouble(data['belief_entropy']),
          processingSummary: _processingSummary(data['processing']),
          processingTags: _processingTags(data['processing']),
        ),
        remainingQuota: remainingQuota,
      );
    } on AppException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '🖼️ [CHAT IMAGE] AppException (${e.statusCode}): ${e.message}',
        );
      }
      if (e.statusCode == 404) {
        return ChatSendResult(
          reply: _errorMessage('Chức năng gửi ảnh hiện không khả dụng.'),
        );
      }
      return ChatSendResult(
        reply: _errorMessage('Không thể xử lý ảnh. Bạn thử lại nhé!'),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🖼️ [CHAT IMAGE] Error: $e');
      }
      return ChatSendResult(
        reply: _errorMessage('Không thể gửi ảnh. Bạn thử lại nhé!'),
      );
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
        final attachment = _parseImageAttachment(map['attachment']);
        final hasImage = attachment?.url != null && attachment!.url!.isNotEmpty;
        if (content.isEmpty && !hasImage) continue;

        final createdAt = DateTime.tryParse(
          map['created_at']?.toString() ?? '',
        );

        messages.add(
          ChatMessage(
            id: 'history_${messages.length}_${DateTime.now().microsecondsSinceEpoch}',
            role: role,
            content: content,
            timestamp: (createdAt ?? DateTime.now()).toLocal(),
            nextNodeType: map['next_node_type']?.toString(),
            planRepaired: _toBool(map['plan_repaired']),
            beliefEntropy: _toDouble(map['belief_entropy']),
            processingSummary: _processingSummary(map['processing']),
            processingTags: _processingTags(map['processing']),
            imageUrl: attachment?.url,
            imageMimeType: attachment?.mimeType,
            imageName: attachment?.fileName,
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
    // Fire-and-forget call to backend.
    // Errors are logged but not surfaced to the caller since the
    // ChatBloc already clears local state synchronously.
    _clearHistoryAsync();
  }

  Future<void> _clearHistoryAsync() async {
    try {
      await _client.delete('/chatbot/history');
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] clearHistory success');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 [CHAT] clearHistory error (best-effort): $e');
      }
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

  String? _extractTextField(
    Map<String, dynamic> data,
    List<String> fieldNames,
  ) {
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

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    if (value is num) return value != 0;
    return false;
  }

  String? _processingSummary(dynamic value) {
    if (value is! Map) return null;
    final summary = value['summary']?.toString().trim() ?? '';
    return summary.isEmpty ? null : summary;
  }

  List<String> _processingTags(dynamic value) {
    if (value is! Map) return const [];
    final rawTags = value['tags'];
    if (rawTags is! List) return const [];

    return rawTags
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  ChatRole? _parseRole(String? roleStr) {
    if (roleStr == null) return null;
    if (roleStr == 'user') return ChatRole.user;
    if (roleStr == 'assistant') return ChatRole.assistant;
    return null;
  }

  _ParsedImageAttachment? _parseImageAttachment(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final attachment = Map<String, dynamic>.from(raw);
    final type = attachment['type']?.toString().trim().toLowerCase();
    if (type != 'image') {
      return null;
    }

    final url = attachment['url']?.toString().trim();
    return _ParsedImageAttachment(
      url: (url == null || url.isEmpty) ? null : url,
      mimeType: attachment['mime_type']?.toString(),
      fileName: attachment['file_name']?.toString(),
    );
  }

  List<Map<String, dynamic>> _toHistoryPayload(List<ChatMessage> history) {
    return history
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }
}

class _ParsedImageAttachment {
  const _ParsedImageAttachment({
    required this.url,
    required this.mimeType,
    required this.fileName,
  });

  final String? url;
  final String? mimeType;
  final String? fileName;
}
