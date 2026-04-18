import '../../../chat/domain/entities/chat_message.dart';

class ChatSendResult {
  const ChatSendResult({required this.reply, this.remainingQuota});

  final ChatMessage reply;
  final int? remainingQuota;
}

/// Abstract interface for chat repository.
abstract class ChatRepository {
  /// Send a message and get an AI response.
  Future<ChatSendResult> sendMessage(
    String userMessage, {
    List<ChatMessage> history = const [],
  });

  /// Load recent conversation history.
  Future<List<ChatMessage>> loadHistory({int limit = 40});

  /// Get initial greeting message.
  ChatMessage getGreeting();

  /// Clear conversation history.
  void clearHistory();
}
