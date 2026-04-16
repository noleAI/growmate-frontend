import 'package:flutter/material.dart';

import '../../../quiz/presentation/widgets/quiz_math_text.dart';
import '../../domain/entities/chat_message.dart';

import '../../../mascot/presentation/pages/mascot_selection_page.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.botMascot,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final MascotId? botMascot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: botMascot != null
                  ? Text(
                      Mascot.all.firstWhere((m) => m.id == botMascot!).emoji,
                      style: const TextStyle(fontSize: 18),
                    )
                  : Icon(
                      Icons.smart_toy_rounded,
                      size: 16,
                      color: colors.onPrimary,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onCopy,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser ? colors.primary : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(theme, isUser),
                    if (!isUser) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isUser) {
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    // Check if content has LaTeX ($...$)
    if (message.content.contains(r'$')) {
      return QuizMathText(
        text: message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.5,
        ),
      );
    }

    return Text(
      message.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.5,
      ),
    );
  }

  static String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
