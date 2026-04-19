import 'package:flutter/material.dart';

import '../../data/models/leaderboard_entry.dart';

/// Top 3 podium với animation scale-in và shimmer trên vị trí 1.
class TopThreePodium extends StatefulWidget {
  const TopThreePodium({super.key, required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  State<TopThreePodium> createState() => _TopThreePodiumState();
}

class _TopThreePodiumState extends State<TopThreePodium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.length < 3) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final first = widget.entries[0];
    final second = widget.entries[1];
    final third = widget.entries[2];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumColumn(
                entry: second,
                height: 118,
                medal: '🥈',
                medalColor: const Color(0xFFC0C0C0),
                theme: theme,
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return _PodiumColumn(
                    entry: first,
                    height: 156,
                    medal: '🥇',
                    medalColor: const Color(0xFFFFD700),
                    theme: theme,
                    shimmerValue: _shimmerController.value,
                  );
                },
              ),
            ),
            Expanded(
              child: _PodiumColumn(
                entry: third,
                height: 100,
                medal: '🥉',
                medalColor: const Color(0xFFCD7F32),
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.medal,
    required this.medalColor,
    required this.theme,
    this.shimmerValue,
  });

  final LeaderboardEntry entry;
  final double height;
  final String medal;
  final Color medalColor;
  final ThemeData theme;
  final double? shimmerValue;

  @override
  Widget build(BuildContext context) {
    final shimmer = shimmerValue;
    final glowOpacity = shimmer != null ? 0.2 + shimmer * 0.4 : 0.0;
    final barFactor = (height / 145).clamp(0.55, 1.0);
    final colors = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 22,
          backgroundColor: medalColor.withValues(alpha: 0.16),
          child: Text(
            entry.initials,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.safeDisplayName,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.weeklyXp} XP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: barFactor,
              widthFactor: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      medalColor.withValues(alpha: 0.22),
                      medalColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: medalColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: shimmer != null
                      ? [
                          BoxShadow(
                            color: medalColor.withValues(alpha: glowOpacity),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${entry.rank}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: medalColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (entry.currentStreak > 0)
                      Text(
                        '🔥 ${entry.currentStreak}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
