import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required ChatRepository repository})
    : _repository = repository,
      super(const ChatInitial());

  final ChatRepository _repository;

  void initialize() {
    final greeting = _repository.getGreeting();
    emit(ChatReady(messages: [greeting]));
  }

  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! ChatReady) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    // Add user message and show typing indicator
    emit(
      current.copyWith(
        messages: [...current.messages, userMessage],
        isAiTyping: true,
      ),
    );

    try {
      final aiResponse = await _repository.sendMessage(trimmed);

      final updated = state;
      if (updated is! ChatReady) return;

      emit(
        updated.copyWith(
          messages: [...updated.messages, aiResponse],
          isAiTyping: false,
        ),
      );
    } catch (e) {
      final updated = state;
      if (updated is! ChatReady) return;

      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: 'Xin lỗi, đã có lỗi xảy ra. Bạn thử lại nhé! 🙏',
        timestamp: DateTime.now(),
      );

      emit(
        updated.copyWith(
          messages: [...updated.messages, errorMessage],
          isAiTyping: false,
        ),
      );
    }
  }

  void clearChat() {
    _repository.clearHistory();
    final greeting = _repository.getGreeting();
    emit(ChatReady(messages: [greeting]));
  }
}
