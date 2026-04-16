import 'package:flutter/material.dart';

import '../../../../../app/i18n/build_context_i18n.dart';
import '../../../../../core/constants/layout.dart';
import 'mood_check_dialog.dart';

/// A visual timeline showing mood entries over recent days.
class MoodTimeline extends StatelessWidget {
  const MoodTimeline({super.key, required this.entries});

  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GrowMateLayout.sectionGap),
          child: Text(
            context.t(vi: 'Chưa có dữ liệu cảm xúc', en: 'No mood data yet'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _MoodDot(entry: entry);
        },
      ),
    );
  }
}

class MoodEntry {
  const MoodEntry({required this.date, required this.mood});

  final DateTime date;
  final MoodType mood;
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabel = '${entry.date.day}/${entry.date.month}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.mood.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
