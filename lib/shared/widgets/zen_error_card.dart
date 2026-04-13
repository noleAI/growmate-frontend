import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../../core/constants/layout.dart';

class ZenErrorCard extends StatelessWidget {
  const ZenErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 22, color: colors.error),
              const SizedBox(width: GrowMateLayout.space8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null || onDismiss != null) ...[
            const SizedBox(height: GrowMateLayout.space12),
            Wrap(
              spacing: GrowMateLayout.space8,
              runSpacing: GrowMateLayout.space8,
              children: [
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: colors.error,
                    ),
                    label: Text(
                      context.t(vi: 'Thử lại', en: 'Retry'),
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (onDismiss != null)
                  TextButton.icon(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.onErrorContainer,
                    ),
                    label: Text(
                      context.t(vi: 'Đóng', en: 'Dismiss'),
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
