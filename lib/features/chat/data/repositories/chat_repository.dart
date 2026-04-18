import 'dart:typed_data';

import '../../../chat/domain/entities/chat_message.dart';

/// Abstract interface for chat repository.
abstract class ChatRepository {
  /// Send a message and get an AI response.
  Future<ChatMessage> sendMessage(String userMessage);

  /// Send an image with an optional question and get an AI response.
  Future<ChatMessage> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  });

  /// Load conversation history from the server (oldest first).
  /// Returns empty list if unavailable.
  Future<List<ChatMessage>> loadHistory();

  /// Get initial greeting message (shown when history is empty).
  ChatMessage getGreeting();

  /// Clear conversation history (local + server).
  void clearHistory();
}
