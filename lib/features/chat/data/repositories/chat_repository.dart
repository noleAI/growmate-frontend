import '../../../chat/domain/entities/chat_message.dart';

/// Abstract interface for chat repository.
abstract class ChatRepository {
  /// Send a message and get an AI response.
  Future<ChatMessage> sendMessage(String userMessage);

  /// Get initial greeting message.
  ChatMessage getGreeting();

  /// Clear conversation history.
  void clearHistory();
}
