import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/zen_button.dart';

/// Friendly popup shown when the user has exhausted their daily chat quota.
///
/// Designed to be non-frustrating with encouraging tone and soft animation.
class QuotaExceededDialog extends StatelessWidget {
  const QuotaExceededDialog({super.key});

  /// Shows the quota exceeded dialog as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuotaExceededDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t(
              vi: 'Hết lượt hôm nay rồi!',
              en: 'Out of chats for today!',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Bạn đã dùng hết 20 lượt chat hôm nay.\nQuay lại ngày mai để tiếp tục trò chuyện với AI nhé! 💪',
              en: 'You\'ve used all 20 chat turns today.\nCome back tomorrow to continue chatting with AI! 💪',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Trong lúc đợi, bạn có thể ôn Sổ tay công thức hoặc xem lại bài sai!',
              en: 'While waiting, you can review the Formula Handbook or revisit past mistakes!',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ZenButton(
            label: context.t(vi: 'Mình hiểu rồi', en: 'Got it'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
