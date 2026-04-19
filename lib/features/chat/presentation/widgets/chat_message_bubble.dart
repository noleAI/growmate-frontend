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
    final bubbleColor = isUser ? colors.primary : colors.surfaceContainerLow;
    final bubbleGradient = isUser
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.primary.withValues(alpha: 0.84)],
          )
        : null;

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
                  color: bubbleColor,
                  gradient: bubbleGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isUser
                        ? colors.primary.withValues(alpha: 0.18)
                        : colors.outlineVariant.withValues(alpha: 0.45),
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
                    if (!isUser) ...[
                      _buildAssistantHeader(theme),
                      const SizedBox(height: 8),
                    ],
                    _buildContent(theme, isUser),
                    if (!isUser && _hasProcessingDetails) ...[
                      const SizedBox(height: 10),
                      _buildProcessingPanel(theme),
                    ],
                    const SizedBox(height: 8),
                    _buildFooter(theme, isUser),
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

    final hasImage =
        (message.imageBytes != null && message.imageBytes!.isNotEmpty) ||
        (message.imageUrl != null && message.imageUrl!.trim().isNotEmpty);
    final hasText = message.content.trim().isNotEmpty;

    if (hasImage) {
      const imageWidth = 220.0;
      const imageHeight = 160.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImagePreview(width: imageWidth, height: imageHeight),
          ),
          if (hasText) ...[
            const SizedBox(height: 8),
            _buildTextContent(theme, textColor),
          ],
        ],
      );
    }

    return _buildTextContent(theme, textColor);
  }

  Widget _buildAssistantHeader(ThemeData theme) {
    final colors = theme.colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                'GrowMate AI',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_nodeLabel != null)
          _buildMetaPill(
            theme,
            label: _nodeLabel!,
            icon: Icons.account_tree_outlined,
          ),
        if (message.planRepaired)
          _buildMetaPill(
            theme,
            label: 'Đã tự sửa kế hoạch',
            icon: Icons.build_circle_outlined,
          ),
      ],
    );
  }

  Widget _buildMetaPill(
    ThemeData theme, {
    required String label,
    required IconData icon,
  }) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({required double width, required double height}) {
    if (message.imageBytes != null && message.imageBytes!.isNotEmpty) {
      return Image.memory(
        message.imageBytes!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        cacheWidth: 660,
        filterQuality: FilterQuality.low,
      );
    }

    final imageUrl = message.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  Widget _buildTextContent(ThemeData theme, Color textColor) {
    return QuizMathText(
      text: message.content,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.55,
      ),
    );
  }

  Widget _buildProcessingPanel(ThemeData theme) {
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Bot vừa xử lý',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ((message.processingSummary ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message.processingSummary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (message.processingTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.processingTags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isUser) {
    final colors = theme.colorScheme;
    final footerColor = isUser
        ? colors.onPrimary.withValues(alpha: 0.74)
        : colors.onSurfaceVariant.withValues(alpha: 0.72);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.beliefEntropy != null && !isUser) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Entropy ${message.beliefEntropy!.toStringAsFixed(2)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          _formatTime(message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: footerColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String? get _nodeLabel {
    return switch (message.nextNodeType?.trim()) {
      'hint' => 'Đang gợi ý',
      'show_hint' => 'Gợi ý học tập',
      'de_stress' => 'Hỗ trợ giảm áp lực',
      'recovery' => 'Nhắc phục hồi tiến độ',
      'hitl_pending' => 'Cần xác nhận thêm',
      'backtrack_repair' => 'Đã dò lại hướng xử lý',
      final raw? when raw.isNotEmpty => raw.replaceAll('_', ' '),
      _ => null,
    };
  }

  bool get _hasProcessingDetails {
    return (message.processingSummary ?? '').trim().isNotEmpty ||
        message.processingTags.isNotEmpty;
  }

  static String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
