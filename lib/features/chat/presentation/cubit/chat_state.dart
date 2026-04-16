import '../../domain/entities/chat_message.dart';

sealed class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatReady extends ChatState {
  const ChatReady({required this.messages, this.isAiTyping = false});

  final List<ChatMessage> messages;
  final bool isAiTyping;

  ChatReady copyWith({List<ChatMessage>? messages, bool? isAiTyping}) {
    return ChatReady(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
    );
  }
}

class ChatError extends ChatState {
  const ChatError(this.message);

  final String message;
}
