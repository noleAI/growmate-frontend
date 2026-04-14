import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
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
                    fontSize: 23,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
    this.distance = 14,
  });

  final Widget child;
  final int delayMs;
  final Duration duration;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final totalDuration = duration + Duration(milliseconds: delayMs);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: totalDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final start = delayMs / totalDuration.inMilliseconds;
        final normalized = start >= 1
            ? 1.0
            : ((value - start) / (1 - start)).clamp(0.0, 1.0);
        final t = normalized.toDouble();

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * distance),
            child: child,
          ),
        );
      },
    );
  }
}

class AiThinkingStateCard extends StatelessWidget {
  const AiThinkingStateCard({super.key, this.message, this.delayMs = 0});

  final String? message;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        radius: GrowMateLayout.specialRadius,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.94),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message ??
                    context.t(
                      vi: 'AI đang phân tích tiến độ của bạn...',
                      en: 'AI is analyzing your progress...',
                    ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({
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
    final theme = Theme.of(context);

    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        padding: padding,
        color:
            color ??
            theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.96),
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
    return AiInsightCard(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      padding: padding,
      delayMs: delayMs,
      color: color,
      child: child,
    );
  }
}

class ProgressItem extends StatelessWidget {
  const ProgressItem({
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
    final barColor = color ?? Theme.of(context).colorScheme.primary;
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
                    color: theme.colorScheme.onSurfaceVariant,
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
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    return ProgressItem(
      label: label,
      value: value,
      caption: caption,
      color: color,
      delayMs: delayMs,
      trailingLabel: trailingLabel,
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
    this.ctaLabel,
    this.badgeLabel,
    this.whyLabel,
    this.delayMs = 40,
  });

  final String topic;
  final String reason;
  final double confidence;
  final VoidCallback? onStart;
  final String? ctaLabel;
  final String? badgeLabel;
  final String? whyLabel;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeConfidence = confidence.clamp(0.0, 1.0).toDouble();
    final resolvedBadgeLabel =
        badgeLabel ?? context.t(vi: 'AI HOẠT ĐỘNG', en: 'AI ACTIVE');
    final resolvedWhyLabel =
        whyLabel ??
        context.t(vi: 'Vì sao AI gợi ý?', en: 'Why this AI suggestion?');
    final resolvedCtaLabel =
        ctaLabel ??
        context.t(vi: 'Bắt đầu phiên gợi ý', en: 'Start suggested session');

    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        radius: GrowMateLayout.specialRadius,
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        resolvedBadgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.t(
                      vi: '${(safeConfidence * 100).toStringAsFixed(0)}% độ tin cậy',
                      en: '${(safeConfidence * 100).toStringAsFixed(0)}% confidence',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.t(
                vi: 'AI đã chọn bước học tiếp theo',
                en: 'AI selected your next study step',
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 24,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              topic,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              resolvedWhyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              maxLines: 2,
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
                        context.t(vi: 'Độ tự tin', en: 'Confidence'),
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
              label: resolvedCtaLabel,
              onPressed: onStart,
              variant: ZenButtonVariant.primary,
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AiResultAction { applyPlan, keepCurrent }

class AiResultModal extends StatelessWidget {
  const AiResultModal({
    super.key,
    required this.didWell,
    required this.needsImprovement,
    required this.nextStep,
    this.title,
    this.subtitle,
    this.primaryLabel,
    this.secondaryLabel,
  });

  final List<String> didWell;
  final List<String> needsImprovement;
  final String nextStep;
  final String? title;
  final String? subtitle;
  final String? primaryLabel;
  final String? secondaryLabel;

  static Future<AiResultAction?> show(
    BuildContext context, {
    required List<String> didWell,
    required List<String> needsImprovement,
    required String nextStep,
    String? title,
    String? subtitle,
    String? primaryLabel,
    String? secondaryLabel,
  }) {
    final resolvedTitle =
        title ??
        context.t(vi: 'Phân tích AI hoàn tất', en: 'AI analysis complete');
    final resolvedPrimaryLabel =
        primaryLabel ??
        context.t(vi: 'Đồng ý lộ trình này', en: 'Accept this roadmap');
    final resolvedSecondaryLabel =
        secondaryLabel ??
        context.t(vi: 'Đổi lộ trình khác', en: 'Switch roadmap');

    return showGeneralDialog<AiResultAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: context.t(vi: 'Kết quả AI', en: 'AI result'),
      barrierColor: Colors.black.withValues(alpha: 0.16),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, _) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: AiResultModal(
                  didWell: didWell,
                  needsImprovement: needsImprovement,
                  nextStep: nextStep,
                  title: resolvedTitle,
                  subtitle: subtitle,
                  primaryLabel: resolvedPrimaryLabel,
                  secondaryLabel: resolvedSecondaryLabel,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.92, end: 1).animate(curved);

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * animation.value,
            sigmaY: 10 * animation.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle =
        title ??
        context.t(vi: 'Phân tích AI hoàn tất', en: 'AI analysis complete');
    final resolvedPrimaryLabel =
        primaryLabel ??
        context.t(vi: 'Đồng ý lộ trình này', en: 'Accept this roadmap');
    final resolvedSecondaryLabel =
        secondaryLabel ??
        context.t(vi: 'Đổi lộ trình khác', en: 'Switch roadmap');
    final safeDidWell = didWell.isEmpty
        ? <String>[
            context.t(
              vi: 'Bạn giữ được nhịp tập trung ổn định trong bài vừa rồi.',
              en: 'You maintained a stable focus rhythm in the last quiz.',
            ),
          ]
        : didWell;
    final safeNeedsImprovement = needsImprovement.isEmpty
        ? <String>[
            context.t(
              vi: 'Ôn lại một khái niệm cốt lõi trước khi vào bài tiếp theo.',
              en: 'Review one core concept before starting the next quiz.',
            ),
          ]
        : needsImprovement;

    return Material(
      type: MaterialType.transparency,
      child: ZenCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerLowest,
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resolvedTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _AiResultSection(
              title: context.t(
                vi: 'Bạn làm tốt ở điểm nào',
                en: 'What you did well',
              ),
              lines: safeDidWell,
              color: theme.colorScheme.tertiary,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 10),
            _AiResultSection(
              title: context.t(
                vi: 'Điểm cần cải thiện',
                en: 'Needs improvement',
              ),
              lines: safeNeedsImprovement,
              color: theme.colorScheme.secondary,
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 10),
            _AiResultSection(
              title: context.t(
                vi: 'Bước tiếp theo AI gợi ý',
                en: 'AI suggested next step',
              ),
              lines: <String>[nextStep],
              color: theme.colorScheme.primary,
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactLayout = constraints.maxWidth < 340;

                final secondaryAction = TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(AiResultAction.keepCurrent);
                  },
                  child: Text(
                    resolvedSecondaryLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );

                final primaryAction = ZenButton(
                  label: resolvedPrimaryLabel,
                  expanded: !compactLayout,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(AiResultAction.applyPlan);
                  },
                );

                if (compactLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      secondaryAction,
                      const SizedBox(height: 8),
                      primaryAction,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: secondaryAction),
                    const SizedBox(width: 8),
                    Expanded(child: primaryAction),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AiResultSection extends StatelessWidget {
  const _AiResultSection({
    required this.title,
    required this.lines,
    required this.color,
    required this.icon,
  });

  final String title;
  final List<String> lines;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
