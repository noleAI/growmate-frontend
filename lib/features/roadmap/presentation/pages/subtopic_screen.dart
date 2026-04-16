import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import 'detail_screen.dart';
import 'roadmap_learning_data.dart';
import '../widgets/roadmap_card_item.dart';

class SubtopicScreen extends StatelessWidget {
  const SubtopicScreen({super.key, required this.topic});

  final RoadmapTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.t(vi: 'Bài học nhỏ', en: 'Subtopics'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Đi từng bước nhỏ để tránh quá tải thông tin.',
              en: 'Move in small steps to avoid information overload.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ...topic.subtopics.asMap().entries.map((entry) {
            final index = entry.key;
            final subtopic = entry.value;
            final progress = (index + 1) / topic.subtopics.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RoadmapCardItem(
                title: subtopic.title,
                subtitle: subtopic.subtitle,
                leading: BadgeLeading(label: subtopic.code),
                progress: progress,
                progressLabel: context.t(
                  vi: 'Tiến độ gợi ý: ${(progress * 100).round()}%',
                  en: 'Suggested progress: ${(progress * 100).round()}%',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(subtopic: subtopic),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
