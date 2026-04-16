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

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumColumn(
              entry: second,
              height: 110,
              medal: '🥈',
              medalColor: const Color(0xFFC0C0C0),
              theme: theme,
            ),
          ),
          // 1st place — tallest + shimmer
          Expanded(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return _PodiumColumn(
                  entry: first,
                  height: 145,
                  medal: '🥇',
                  medalColor: const Color(0xFFFFD700),
                  theme: theme,
                  shimmerValue: _shimmerController.value,
                );
              },
            ),
          ),
          // 3rd place
          Expanded(
            child: _PodiumColumn(
              entry: third,
              height: 90,
              medal: '🥉',
              medalColor: const Color(0xFFCD7F32),
              theme: theme,
            ),
          ),
        ],
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          entry.displayName.split(' ').last,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
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
                  color: medalColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
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
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: medalColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
