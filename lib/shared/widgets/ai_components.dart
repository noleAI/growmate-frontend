import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';
import 'zen_button.dart';
import 'zen_card.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomSpacing = 12,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    color: GrowMateColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GrowMateColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final int delayMs;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final t = ((value * 1.15) - (delayMs / 1000)).clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.delayMs = 0,
    this.color,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final int delayMs;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        padding: padding,
        color: color ?? GrowMateColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              bottomSpacing: 10,
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class ProgressBarItem extends StatelessWidget {
  const ProgressBarItem({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.color,
    this.delayMs = 0,
    this.trailingLabel,
  });

  final String label;
  final double value;
  final String? caption;
  final Color? color;
  final int delayMs;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    final barColor = color ?? GrowMateColors.primary;
    final theme = Theme.of(context);

    return FadeSlideIn(
      delayMs: delayMs,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  trailingLabel ?? '${(safeValue * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: safeValue),
                duration: Duration(milliseconds: 650 + delayMs),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return LinearProgressIndicator(
                    minHeight: 8,
                    value: animatedValue,
                    backgroundColor: GrowMateColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  );
                },
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(
                caption!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: GrowMateColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AiRecommendationCard extends StatelessWidget {
  const AiRecommendationCard({
    super.key,
    required this.topic,
    required this.reason,
    required this.confidence,
    required this.onStart,
    this.ctaLabel = 'Bắt đầu ngay',
  });

  final String topic;
  final String reason;
  final double confidence;
  final VoidCallback? onStart;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeConfidence = confidence.clamp(0.0, 1.0).toDouble();

    return FadeSlideIn(
      delayMs: 40,
      child: ZenCard(
        radius: GrowMateLayout.specialRadius,
        padding: const EdgeInsets.all(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'AI RECOMMENDATION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hôm nay bạn nên học…',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 26,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              topic,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontSize: 34,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Độ tự tin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: safeConfidence,
                          backgroundColor: Colors.white.withValues(alpha: 0.24),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(safeConfidence * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ZenButton(
              label: ctaLabel,
              onPressed: onStart,
              variant: ZenButtonVariant.secondary,
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: GrowMateColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
