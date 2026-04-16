import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Spam warning dialog — "Chậm lại suy nghĩ kỹ nhé! 🤔"
///
/// Shown when the user submits multiple answers in rapid succession (< 2s).
/// Auto-dismisses after [autoDismissSeconds] seconds.
class SpamWarningDialog extends StatefulWidget {
  const SpamWarningDialog({
    super.key,
    this.consecutiveCount = 2,
    this.autoDismissSeconds = 5,
  });

  final int consecutiveCount;
  final int autoDismissSeconds;

  static Future<void> show(BuildContext context, {int consecutiveCount = 2}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SpamWarningDialog(consecutiveCount: consecutiveCount),
    );
  }

  @override
  State<SpamWarningDialog> createState() => _SpamWarningDialogState();
}

class _SpamWarningDialogState extends State<SpamWarningDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.autoDismissSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                  'Trả lời quá nhanh (${widget.consecutiveCount} lần). '
                  'Đọc kỹ đề rồi chọn nhé.',
              en:
                  'Answering too fast (${widget.consecutiveCount} times). '
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
            child: Text(
              context.t(
                vi: 'Mình hiểu rồi ($_remaining)',
                en: 'Got it ($_remaining)',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
