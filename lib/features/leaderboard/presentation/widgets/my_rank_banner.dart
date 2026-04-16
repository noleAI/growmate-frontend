import 'package:flutter/material.dart';

import '../../data/models/leaderboard_entry.dart';

/// Banner sticky ở bottom hiển thị rank của user hiện tại.
class MyRankBanner extends StatelessWidget {
  const MyRankBanner({super.key, required this.myEntry});

  final LeaderboardEntry myEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.85),
            colors.primaryContainer,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text('🏅', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bạn đang hạng #${myEntry.rank}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${myEntry.weeklyXp} XP tuần này · 🔥 ${myEntry.currentStreak} ngày',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '⭐ ${myEntry.weeklyXp} XP',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
