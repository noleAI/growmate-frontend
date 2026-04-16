import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/user_badge.dart';

/// Grid 3 cột hiển thị tất cả badges (locked + unlocked).
class BadgeShowcaseGrid extends StatelessWidget {
  const BadgeShowcaseGrid({
    super.key,
    required this.allBadges,
    required this.myBadges,
  });

  final List<UserBadge> allBadges;
  final List<UserBadge> myBadges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myBadgeIds = myBadges.map((b) => b.id).toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final myBadge = myBadgeIds.contains(badge.id)
            ? myBadges.firstWhere((b) => b.id == badge.id)
            : null;
        final isUnlocked = myBadge != null;

        return _BadgeCell(
          badge: myBadge ?? badge,
          isUnlocked: isUnlocked,
          theme: theme,
        );
      },
    );
  }
}

class _BadgeCell extends StatelessWidget {
  const _BadgeCell({
    required this.badge,
    required this.isUnlocked,
    required this.theme,
  });

  final UserBadge badge;
  final bool isUnlocked;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final dateFormatter = DateFormat('dd/MM/yy');

    return Tooltip(
      message: isUnlocked
          ? badge.description
          : badge.unlockCondition ?? badge.description,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? colors.primaryContainer.withValues(alpha: 0.4)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? colors.primary.withValues(alpha: 0.5)
                : colors.outlineVariant.withValues(alpha: 0.4),
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Text(
                  badge.iconEmoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.transparent,
                  ),
                ),
                if (!isUnlocked)
                  const Positioned.fill(
                    child: Center(
                      child: Text('🔒', style: TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              badge.badgeName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUnlocked
                    ? colors.onSurface
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked && badge.earnedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                dateFormatter.format(badge.earnedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
