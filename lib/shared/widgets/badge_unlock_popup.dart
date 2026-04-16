import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../../core/constants/layout.dart';
import '../../features/achievement/data/models/achievement_badge.dart';
import '../../features/achievement/presentation/achievement_i18n.dart';

/// A celebratory popup shown when a badge is unlocked.
class BadgeUnlockPopup extends StatefulWidget {
  const BadgeUnlockPopup({super.key, required this.badge});

  final AchievementBadge badge;

  /// Shows the badge unlock popup for each badge in the list, sequentially.
  static Future<void> showAll(
    BuildContext context,
    List<AchievementBadge> badges,
  ) async {
    for (final badge in badges) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => BadgeUnlockPopup(badge: badge),
      );
    }
  }

  @override
  State<BadgeUnlockPopup> createState() => _BadgeUnlockPopupState();
}

class _BadgeUnlockPopupState extends State<BadgeUnlockPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _badgeIcon(String iconKey) {
    return switch (iconKey) {
      'rocket' => Icons.rocket_launch_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'spa' => Icons.spa_rounded,
      'psychology_alt' => Icons.psychology_alt_rounded,
      'calendar_month' => Icons.calendar_month_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon with glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primaryContainer,
                        colors.tertiaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _badgeIcon(widget.badge.iconKey),
                    size: 40,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space16),
                Text('🏅', style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  context.t(vi: 'Huy hiệu mới!', en: 'New Badge!'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizedBadgeTitle(context, widget.badge),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizedBadgeDescription(context, widget.badge),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.sectionGap),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.t(vi: 'Tuyệt vời! 🎉', en: 'Awesome! 🎉'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
