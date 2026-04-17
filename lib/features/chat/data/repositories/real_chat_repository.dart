import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

/// Chat repository that calls POST /api/v1/chatbot/chat
/// — enforces content policy on the backend side.
class RealChatRepository implements ChatRepository {
  RealChatRepository({
    required Future<String?> Function() getAccessToken,
    http.Client? httpClient,
  })  : _getAccessToken = getAccessToken,
        _httpClient = httpClient ?? http.Client();

  final Future<String?> Function() _getAccessToken;
  final http.Client _httpClient;

  /// In-memory history kept for fallback when DB load fails.
  final List<Map<String, String>> _localHistory = [];

  String get _baseUrl => ApiConfig.restApiBaseUrl;

  // ── ChatRepository interface ────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendMessage(String userMessage) async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return _errorMessage('Bạn cần đăng nhập để dùng tính năng này.');
    }

    final uri = Uri.parse('$_baseUrl/chatbot/chat');

    final body = jsonEncode(<String, dynamic>{
      'message': userMessage,
      'history': _localHistory.take(20).toList(),
    });

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      if (kDebugMode) {
        debugPrint('💬 [Chatbot] ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['reply']?.toString() ?? '';

        // Update local history
        _localHistory
          ..add({'role': 'user', 'content': userMessage})
          ..add({'role': 'assistant', 'content': reply});

        // Keep rolling window
        if (_localHistory.length > 40) {
          _localHistory.removeRange(0, _localHistory.length - 40);
        }

        return ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: reply,
          timestamp: DateTime.now(),
        );
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = data['detail'];
        final msg = (detail is Map ? detail['message'] : null) as String? ??
            'Bạn đã hết lượt chat hôm nay. Quay lại vào ngày mai nhé! 🌙';
        return _errorMessage(msg);
      }

      return _errorMessage('Lỗi kết nối (${response.statusCode}). Thử lại sau nhé!');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chatbot] Error: $e');
      return _errorMessage('Không thể kết nối đến server. Kiểm tra mạng và thử lại nhé!');
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
  Future<List<ChatMessage>> loadHistory() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/chatbot/history?limit=40');
    try {
      final response = await _httpClient
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['messages'] as List<dynamic>? ?? [];

      return rawList.indexed.map((entry) {
        final idx = entry.$1;
        final m = entry.$2 as Map<String, dynamic>;
        final role = m['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
        DateTime ts = DateTime.now();
        try {
          ts = DateTime.parse(m['created_at'] as String? ?? '');
        } catch (_) {}
        return ChatMessage(
          id: 'hist_$idx',
          role: role,
          content: m['content']?.toString() ?? '',
          timestamp: ts,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chatbot] loadHistory error: $e');
      return [];
    }
  }

  @override
  void clearHistory() {
    _localHistory.clear();
  }


  // ── Helpers ─────────────────────────────────────────────────────────────────

  ChatMessage _errorMessage(String text) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: text,
      timestamp: DateTime.now(),
    );
  }
}
