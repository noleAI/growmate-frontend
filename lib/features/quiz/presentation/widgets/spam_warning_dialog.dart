import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Spam warning dialog — "Chậm lại suy nghĩ kỹ nhé! 🤔"
///
/// Shown when the user submits multiple answers in rapid succession (< 2s).
class SpamWarningDialog extends StatelessWidget {
  const SpamWarningDialog({super.key, this.consecutiveCount = 2});

  final int consecutiveCount;

  static Future<void> show(BuildContext context, {int consecutiveCount = 2}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SpamWarningDialog(consecutiveCount: consecutiveCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤔', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            context.t(
              vi: 'Chậm lại suy nghĩ kỹ nhé!',
              en: 'Slow down and think carefully!',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi:
                  'Trả lời quá nhanh ($consecutiveCount lần). '
                  'Đọc kỹ đề rồi chọn nhé.',
              en:
                  'Answering too fast ($consecutiveCount times). '
                  'Read carefully before choosing.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t(vi: 'Mình hiểu rồi', en: 'Got it')),
          ),
        ),
      ],
    );
  }
}
