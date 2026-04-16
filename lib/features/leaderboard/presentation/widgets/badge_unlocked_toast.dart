import 'package:flutter/material.dart';

import '../../data/models/user_badge.dart';

/// Toast animation khi user vừa đạt badge mới.
class BadgeUnlockedToast extends StatefulWidget {
  const BadgeUnlockedToast({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  final UserBadge badge;
  final VoidCallback onDismiss;

  static Future<void> show(BuildContext context, UserBadge badge) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'badge_toast',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, secondAnim) => BadgeUnlockedToast(
        badge: badge,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<BadgeUnlockedToast> createState() => _BadgeUnlockedToastState();
}

class _BadgeUnlockedToastState extends State<BadgeUnlockedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'Badge mới!',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.badge.iconEmoji,
                style: const TextStyle(fontSize: 52),
              ),
              const SizedBox(height: 8),
              Text(
                widget.badge.badgeName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.badge.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(
                'Nhấn để đóng',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
