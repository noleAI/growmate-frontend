import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import 'roadmap_learning_data.dart';
import 'subtopic_screen.dart';
import '../widgets/roadmap_card_item.dart';

class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.subject});

  final RoadmapSubject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(subject.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.t(vi: 'Chủ đề', en: 'Topics'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Chọn chủ đề để xem các phần kiến thức chi tiết.',
              en: 'Pick a topic to explore detailed learning sections.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ...subject.topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RoadmapCardItem(
                title: topic.title,
                subtitle: topic.subtitle,
                leading: IconLeading(
                  icon: index.isEven
                      ? Icons.functions_rounded
                      : Icons.auto_graph_rounded,
                ),
                progress: 0.45,
                progressLabel: context.t(
                  vi: '${topic.subtopics.length} bài học',
                  en: '${topic.subtopics.length} lessons',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SubtopicScreen(topic: topic),
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
