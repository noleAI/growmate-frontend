import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';

import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_quick_chips.dart';
import '../widgets/chat_typing_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mascot/presentation/pages/mascot_selection_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChatCubit(repository: context.read<ChatRepository>())..initialize(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  MascotId? _selectedMascot;

  @override
  void initState() {
    super.initState();
    _loadMascot();
  }

  Future<void> _loadMascot() async {
    final prefs = await SharedPreferences.getInstance();
    final mascotName = prefs.getString('selected_mascot');
    setState(() {
      _selectedMascot = MascotId.values.firstWhere(
        (e) => e.name == mascotName,
        orElse: () => MascotId.cat,
      );
    });
  }

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().sendMessage(text);
    _textController.clear();
    _focusNode.unfocus();
    _scrollToBottom();
  }

  void _showClearChatDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t(vi: 'Xóa cuộc trò chuyện?', en: 'Clear chat?')),
        content: Text(
          context.t(
            vi: 'Tất cả tin nhắn sẽ bị xóa.',
            en: 'All messages will be deleted.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t(vi: 'Hủy', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ChatCubit>().clearChat();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(context.t(vi: 'Xóa', en: 'Clear')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: colors.primary),
        titleSpacing: 0,
        title: Row(
          children: [
            if (_selectedMascot != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  Mascot.all.firstWhere((m) => m.id == _selectedMascot!).emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            Text(
              context.t(vi: 'Chat AI', en: 'Chat AI'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showClearChatDialog,
            icon: Icon(Icons.delete_outline_rounded, color: colors.primary),
            tooltip: context.t(vi: 'Xóa cuộc trò chuyện', en: 'Clear chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatReady) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: colors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is ChatReady) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Text(
                        context.t(
                          vi: 'Bắt đầu cuộc trò chuyện!',
                          en: 'Start a conversation!',
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    itemCount:
                        state.messages.length + (state.isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isAiTyping) {
                        return const ChatTypingIndicator();
                      }
                      final isBot =
                          state.messages[index].role == ChatRole.assistant;
                      return ChatMessageBubble(
                        message: state.messages[index],
                        onCopy: () {
                          Clipboard.setData(
                            ClipboardData(text: state.messages[index].content),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.t(vi: 'Đã sao chép', en: 'Copied'),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                        },
                        botMascot: isBot ? _selectedMascot : null,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Quick chips
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatReady && !state.isAiTyping) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChatQuickChips(onChipTapped: _sendMessage),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              8,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: context.t(
                          vi: 'Hỏi GrowMate AI...',
                          en: 'Ask GrowMate AI...',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    final isTyping = state is ChatReady && state.isAiTyping;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: IconButton.filled(
                        onPressed: isTyping
                            ? null
                            : () => _sendMessage(_textController.text),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          disabledBackgroundColor:
                              colors.surfaceContainerHighest,
                        ),
                        icon: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: isTyping
                              ? colors.onSurfaceVariant
                              : colors.onPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
