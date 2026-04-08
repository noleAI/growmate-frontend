import 'package:flutter/material.dart';

class EmotionTaskProgress extends StatelessWidget {
  const EmotionTaskProgress({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    this.tasks = const <String>[],
    this.title = 'Today progress',
  });

  final int completedTasks;
  final int totalTasks;
  final List<String> tasks;
  final String title;

  double get _progress {
    if (totalTasks <= 0) {
      return 0;
    }
    return (completedTasks / totalTasks).clamp(0.0, 1.0).toDouble();
  }

  _MoodState get _moodState {
    final value = _progress;
    if (value >= 0.8) {
      return const _MoodState(
        icon: Icons.sentiment_very_satisfied_rounded,
        label: 'Great pace',
      );
    }
    if (value >= 0.5) {
      return const _MoodState(
        icon: Icons.sentiment_satisfied_alt_rounded,
        label: 'Steady progress',
      );
    }
    if (value >= 0.25) {
      return const _MoodState(
        icon: Icons.sentiment_neutral_rounded,
        label: 'Small steps count',
      );
    }
    return const _MoodState(
      icon: Icons.self_improvement_rounded,
      label: 'Start with one task',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mood = _moodState;
    final percent = (_progress * 100).round();
    final visibleTasks = tasks.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mood.icon, color: colorScheme.primary, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        '$percent% complete • ${mood.label}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SegmentedCalmProgress(progress: _progress),
            const SizedBox(height: 14),
            Text(
              '$completedTasks of $totalTasks tasks done',
              style: theme.textTheme.labelLarge,
            ),
            if (visibleTasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...visibleTasks.asMap().entries.map((entry) {
                final taskIndex = entry.key;
                final taskText = entry.value;
                final done = taskIndex < completedTasks;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: done
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          taskText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: done
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentedCalmProgress extends StatelessWidget {
  const _SegmentedCalmProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const segments = 8;
    final active = (progress * segments).round();

    return Row(
      children: List.generate(segments, (index) {
        final filled = index < active;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 6),
            height: 10,
            decoration: BoxDecoration(
              color: filled
                  ? colorScheme.tertiaryContainer
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        );
      }),
    );
  }
}

class _MoodState {
  const _MoodState({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
