import 'package:flutter/material.dart';

import '../../../../data/models/agentic_models.dart';
import '../../../../shared/widgets/ai_reflection_widget.dart';

/// Summary widget hiển thị khi session kết thúc.
/// Cho HS biết AI đã suy luận bao nhiêu bước, dùng chế độ gì.
class SessionSummaryWidget extends StatelessWidget {
  const SessionSummaryWidget({
    super.key,
    required this.totalSteps,
    required this.reasoningMode,
    this.latestReflection,
  });

  final int totalSteps;
  final String reasoningMode;
  final ReflectionResult? latestReflection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              icon: Icons.psychology,
              label: 'Bước suy luận',
              value: '$totalSteps',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildStat(
              icon: Icons.smart_toy,
              label: 'Chế độ AI',
              value: reasoningMode == 'agentic' ? 'Agentic' : 'Adaptive',
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),

        // Reflection summary
        if (latestReflection != null) ...[
          const SizedBox(height: 16),
          AiReflectionWidget(
            reflection: latestReflection!,
            stepNumber: totalSteps,
          ),
        ],
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
