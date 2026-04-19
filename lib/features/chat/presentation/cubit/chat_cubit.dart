import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_quota_cubit.dart';
import 'chat_state.dart';

enum ChatSendOutcome { sent, quotaExceeded, failed, ignored }

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required ChatRepository repository, ChatQuotaCubit? quotaCubit})
    : _repository = repository,
      _quotaCubit = quotaCubit,
      super(const ChatInitial());

  final ChatRepository _repository;
  final ChatQuotaCubit? _quotaCubit;

  Future<void> initialize() async {
    final quotaCubit = _quotaCubit;

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

    if (quotaCubit != null) {
      unawaited(_syncChatQuota(quotaCubit));
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

  Future<void> sendImageMessage({
    required String text,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    final current = state;
    if (current is! ChatReady) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty && imageBytes.isEmpty) return;

    final userMessage = ChatMessage(
      id: 'user_img_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
      imageName: imageName,
      imageMimeType: imageMimeType,
    );

    emit(
      current.copyWith(
        messages: [...current.messages, userMessage],
        isAiTyping: true,
      ),
    );

    try {
      final sendResult = await _repository.sendImageMessage(
        userMessage: trimmed,
        imageBytes: imageBytes,
        imageName: imageName,
        imageMimeType: imageMimeType,
      );

      final updated = state;
      if (updated is! ChatReady) return;

      emit(
        updated.copyWith(
          messages: [...updated.messages, sendResult.reply],
          isAiTyping: false,
        ),
      );

      final quotaCubit = _quotaCubit;
      if (quotaCubit != null) {
        if (sendResult.remainingQuota != null) {
          quotaCubit.syncFromRemaining(sendResult.remainingQuota!);
        } else {
          quotaCubit.useOne();
        }
      }
    } catch (e) {
      final updated = state;
      if (updated is! ChatReady) return;

      final errorMessage = ChatMessage(
        id: 'error_img_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: 'Mình chưa gửi được ảnh lúc này. Bạn thử lại nhé! 🙏',
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
    emit(ChatReady(messages: [_repository.getGreeting()]));
  }

  Future<void> _syncChatQuota(ChatQuotaCubit quotaCubit) async {
    try {
      final quota = await _repository.fetchQuota();
      quotaCubit.setQuota(quota);
    } catch (_) {
      // Preserve chat UX if quota fetch fails; send-time 429 still updates state.
    }
  }

  List<ChatMessage> _historyForRequest(List<ChatMessage> messages) {
    return messages
        .where((m) => !m.id.startsWith('greeting_'))
        .where((m) => m.role == ChatRole.user || m.role == ChatRole.assistant)
        .toList(growable: false);
  }
}
