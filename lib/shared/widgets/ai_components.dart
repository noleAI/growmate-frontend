import 'dart:ui';

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
                    fontSize: 23,
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w800,
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
  const AiThinkingStateCard({
    super.key,
    this.message = 'AI đang phân tích tiến độ của bạn...',
    this.delayMs = 0,
  });

  final String message;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        radius: GrowMateLayout.specialRadius,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        color: Colors.white.withValues(alpha: 0.94),
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
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: GrowMateColors.textSecondary,
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
    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        padding: padding,
        color: color ?? Colors.white.withValues(alpha: 0.96),
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
    this.ctaLabel = 'Bắt đầu phiên gợi ý',
    this.badgeLabel = 'AI HOẠT ĐỘNG',
    this.whyLabel = 'Vì sao AI gợi ý?',
    this.delayMs = 40,
  });

  final String topic;
  final String reason;
  final double confidence;
  final VoidCallback? onStart;
  final String ctaLabel;
  final String badgeLabel;
  final String whyLabel;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeConfidence = confidence.clamp(0.0, 1.0).toDouble();

    return FadeSlideIn(
      delayMs: delayMs,
      child: ZenCard(
        radius: GrowMateLayout.specialRadius,
        padding: const EdgeInsets.all(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3FA4), Color(0xFF1D4ED8), Color(0xFF2563EB)],
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
                        badgeLabel,
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
                    '${(safeConfidence * 100).toStringAsFixed(0)}% độ tin cậy',
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
              'AI đã chọn bước học tiếp theo',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 24,
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
              whyLabel,
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
    this.title = 'Phân tích AI hoàn tất',
    this.subtitle,
    this.primaryLabel = 'Áp dụng lộ trình mới',
    this.secondaryLabel = 'Giữ lộ trình hiện tại',
  });

  final List<String> didWell;
  final List<String> needsImprovement;
  final String nextStep;
  final String title;
  final String? subtitle;
  final String primaryLabel;
  final String secondaryLabel;

  static Future<AiResultAction?> show(
    BuildContext context, {
    required List<String> didWell,
    required List<String> needsImprovement,
    required String nextStep,
    String title = 'Phân tích AI hoàn tất',
    String? subtitle,
    String primaryLabel = 'Áp dụng lộ trình mới',
    String secondaryLabel = 'Giữ lộ trình hiện tại',
  }) {
    return showGeneralDialog<AiResultAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Kết quả AI',
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
                  title: title,
                  subtitle: subtitle,
                  primaryLabel: primaryLabel,
                  secondaryLabel: secondaryLabel,
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
    final safeDidWell = didWell.isEmpty
        ? const <String>[
            'Bạn giữ được nhịp tập trung ổn định trong bài vừa rồi.',
          ]
        : didWell;
    final safeNeedsImprovement = needsImprovement.isEmpty
        ? const <String>[
            'Ôn lại một khái niệm cốt lõi trước khi vào bài tiếp theo.',
          ]
        : needsImprovement;

    return Material(
      type: MaterialType.transparency,
      child: ZenCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FBFF), Color(0xFFF1F5FF)],
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
                    color: GrowMateColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: GrowMateColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: GrowMateColors.textPrimary,
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
                  color: GrowMateColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _AiResultSection(
              title: 'Bạn làm tốt ở điểm nào',
              lines: safeDidWell,
              color: GrowMateColors.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 10),
            _AiResultSection(
              title: 'Điểm cần cải thiện',
              lines: safeNeedsImprovement,
              color: GrowMateColors.warningSoft,
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 10),
            _AiResultSection(
              title: 'Bước tiếp theo AI gợi ý',
              lines: <String>[nextStep],
              color: GrowMateColors.primary,
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(AiResultAction.keepCurrent);
                    },
                    child: Text(
                      secondaryLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: GrowMateColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ZenButton(
                  label: primaryLabel,
                  expanded: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(AiResultAction.applyPlan);
                  },
                ),
              ],
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
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GrowMateColors.textPrimary,
                  fontWeight: FontWeight.w700,
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
                  color: GrowMateColors.textSecondary,
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
