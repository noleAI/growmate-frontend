import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';
import 'zen_button.dart';
import 'zen_card.dart';

class ZenEmptyState extends StatelessWidget {
  const ZenEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.centered = true,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool centered;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = accentColor ?? colors.primary;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return ZenCard(
      radius: GrowMateLayout.cardRadius,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      border: Border.all(color: accent.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (primaryLabel != null && onPrimaryPressed != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: SizedBox(
                width: centered ? double.infinity : null,
                child: ZenButton(
                  label: primaryLabel!,
                  expanded: centered,
                  onPressed: onPrimaryPressed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
