import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../../quota/presentation/cubit/quota_cubit.dart';
import 'chat_state.dart';

enum ChatSendOutcome { sent, quotaExceeded, failed, ignored }

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required ChatRepository repository, QuotaCubit? quotaCubit})
    : _repository = repository,
      _quotaCubit = quotaCubit,
      super(const ChatInitial());

  final ChatRepository _repository;
  final QuotaCubit? _quotaCubit;

  Future<void> initialize() async {
    try {
      final history = await _repository.loadHistory();
      if (history.isNotEmpty) {
        emit(ChatReady(messages: history));
      } else {
        emit(ChatReady(messages: [_repository.getGreeting()]));
      }
    } catch (_) {
      emit(ChatReady(messages: [_repository.getGreeting()]));
    }

    final quotaCubit = _quotaCubit;
    if (quotaCubit != null) {
      unawaited(quotaCubit.loadQuota(silent: true));
    }
  }

  Future<ChatSendOutcome> sendMessage(String text) async {
    final current = state;
    if (current is! ChatReady) return ChatSendOutcome.ignored;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return ChatSendOutcome.ignored;

    final quotaCubit = _quotaCubit;
    if (quotaCubit != null && !quotaCubit.canChat) {
      return ChatSendOutcome.quotaExceeded;
    }

    final historySnapshot = _historyForRequest(current.messages);

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
      final sendResult = await _repository.sendMessage(
        trimmed,
        history: historySnapshot,
      );

      final updated = state;
      if (updated is! ChatReady) return ChatSendOutcome.ignored;

      emit(
        updated.copyWith(
          messages: [...updated.messages, sendResult.reply],
          isAiTyping: false,
        ),
      );

      if (quotaCubit != null) {
        if (sendResult.remainingQuota != null) {
          quotaCubit.syncFromRemaining(sendResult.remainingQuota!);
        } else {
          quotaCubit.useOne();
        }
      }

      return ChatSendOutcome.sent;
    } on RateLimitException catch (e) {
      _quotaCubit?.markExceeded(details: e.details);

      final updated = state;
      if (updated is! ChatReady) return ChatSendOutcome.quotaExceeded;

      final quotaMessage = ChatMessage(
        id: 'quota_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        content:
            'Bạn đã dùng hết lượt chat hôm nay rồi. Mình sẽ luôn sẵn sàng hỗ trợ bạn vào ngày mai nhé! 🌙',
        timestamp: DateTime.now(),
      );

      emit(
        updated.copyWith(
          messages: [...updated.messages, quotaMessage],
          isAiTyping: false,
        ),
      );

      return ChatSendOutcome.quotaExceeded;
    } catch (_) {
      final updated = state;
      if (updated is! ChatReady) return ChatSendOutcome.failed;

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

      return ChatSendOutcome.failed;
    }
  }

  void clearChat() {
    _repository.clearHistory();
    final greeting = _repository.getGreeting();
    emit(ChatReady(messages: [greeting]));
  }

  List<ChatMessage> _historyForRequest(List<ChatMessage> messages) {
    return messages
        .where((m) => !m.id.startsWith('greeting_'))
        .where((m) => m.role == ChatRole.user || m.role == ChatRole.assistant)
        .toList(growable: false);
  }
}
