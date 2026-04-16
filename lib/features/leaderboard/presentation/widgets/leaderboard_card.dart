import 'package:flutter/material.dart';

import '../../data/models/leaderboard_entry.dart';

/// Một row trong bảng xếp hạng.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({super.key, required this.entry, this.isMe = false});

  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isMe
            ? colors.primaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(
                color: colors.primary.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: entry.rank <= 3
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Avatar circle
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName[0].toUpperCase()
                    : (isMe ? 'T' : '?'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMe
                        ? (entry.displayName.isNotEmpty
                              ? '${entry.displayName} (Bạn)'
                              : 'Bạn')
                        : entry.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.currentStreak > 0)
                    Text(
                      '🔥 ${entry.currentStreak} ngày',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.weeklyXp}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                Text(
                  'XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
