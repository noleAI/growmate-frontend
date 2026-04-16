import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';
import '../ai_components.dart';

/// Shared visual wrapper for all AI block types.
///
/// Renders a labelled card with the block-type overline, left accent bar, and
/// the standard staggered [FadeSlideIn] entrance animation.
class AiBlockBase extends StatelessWidget {
  const AiBlockBase({
    super.key,
    required this.blockLabel,
    required this.child,
    this.accentColor,
    this.delayMs = 0,
    this.padding = GrowMateLayout.cardPaddingAi,
  });

  final String blockLabel;
  final Widget child;
  final Color? accentColor;
  final int delayMs;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? GrowMateColors.aiCore(theme.brightness);

    return FadeSlideIn(
      delayMs: delayMs,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
          border: Border(left: BorderSide(color: accent, width: 3)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overline label
              Text(
                blockLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
