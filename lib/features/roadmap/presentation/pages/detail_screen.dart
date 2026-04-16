import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import 'roadmap_learning_data.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.subtopic});

  final RoadmapSubtopic subtopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${subtopic.code}: ${subtopic.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            subtopic.subtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            subtopic.explanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            context.t(vi: 'Công thức', en: 'Formulas'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...subtopic.formulas.map(
            (formula) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(
                  formula,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
