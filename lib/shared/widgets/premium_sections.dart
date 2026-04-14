import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../../core/constants/layout.dart';
import 'zen_button.dart';

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(GrowMateLayout.contentGap),
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: GrowMateLayout.space8),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          child,
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = accent ?? colors.primary;

    return Container(
      constraints: const BoxConstraints(minWidth: 94),
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.space12,
        vertical: GrowMateLayout.space12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.trailing,
    this.color,
    this.delayMs = 0,
  });

  final String label;
  final double value;
  final String? caption;
  final String? trailing;
  final Color? color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final barColor = color ?? colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: GrowMateLayout.contentGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                trailing ?? '${(safeValue * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: safeValue),
              duration: Duration(milliseconds: 700 + delayMs),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return LinearProgressIndicator(
                  minHeight: 6,
                  value: animated,
                  backgroundColor: colors.surfaceContainerHigh.withValues(
                    alpha: 0.75,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                );
              },
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: GrowMateLayout.space8),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AIHero extends StatelessWidget {
  const AIHero({
    super.key,
    required this.title,
    required this.topic,
    required this.reason,
    required this.confidence,
    required this.ctaLabel,
    required this.onPressed,
  });

  final String title;
  final String topic;
  final String reason;
  final double confidence;
  final String ctaLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final safeConfidence = confidence.clamp(0.0, 1.0).toDouble();
    final theme = Theme.of(context);
    final primaryHsl = HSLColor.fromColor(theme.colorScheme.primary);
    final gradientStart = primaryHsl
        .withLightness(
          (primaryHsl.lightness + 0.08).clamp(0.0, 0.85).toDouble(),
        )
        .withSaturation(
          (primaryHsl.saturation - 0.05).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    final gradientMid = theme.colorScheme.primary;
    final gradientEnd = primaryHsl
        .withLightness(
          (primaryHsl.lightness + 0.14).clamp(0.0, 0.88).toDouble(),
        )
        .withSaturation(
          (primaryHsl.saturation - 0.1).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientMid, gradientEnd],
          stops: const [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -34,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -6,
            top: 18,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Color(0xFFE5EDFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.t(
                            vi: 'AI gợi ý phiên mới',
                            en: 'AI-suggested session',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFF4F8FF),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(safeConfidence * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFF2F7FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GrowMateLayout.contentGap),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.16,
                ),
              ),
              const SizedBox(height: GrowMateLayout.space8),
              Text(
                topic,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFFE7F1FF),
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -0.32,
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              Text(
                reason,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: safeConfidence,
                  backgroundColor: Colors.white.withValues(alpha: 0.26),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.tertiary,
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.contentGap),
              ZenButton(
                label: ctaLabel,
                onPressed: onPressed,
                variant: ZenButtonVariant.primary,
                backgroundColor: gradientMid.withValues(alpha: 0.85),
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: GrowMateLayout.contentGap,
                  vertical: GrowMateLayout.space12,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
