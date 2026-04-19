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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.92),
                colors.primaryContainer,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🏅', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vị trí của bạn: #${myEntry.rank}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BannerMetric(
                          label: '${myEntry.weeklyXp} XP kỳ này',
                          textColor: colors.onPrimary,
                        ),
                        _BannerMetric(
                          label: '🔥 ${myEntry.currentStreak} ngày',
                          textColor: colors.onPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    myEntry.initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'nhịp học',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.82),
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

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
