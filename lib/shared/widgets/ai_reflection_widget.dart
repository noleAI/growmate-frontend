import 'package:flutter/material.dart';

import '../../data/models/agentic_models.dart';

/// Widget hiển thị kết quả self-reflection của AI.
class AiReflectionWidget extends StatelessWidget {
  const AiReflectionWidget({
    super.key,
    required this.reflection,
    required this.stepNumber,
  });

  final ReflectionResult reflection;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI tự đánh giá (sau $stepNumber bước)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildEffectivenessBadge(theme),
            ],
          ),
          const SizedBox(height: 8),

          // Trend indicators
          Row(
            children: [
              _buildTrend(
                'Kiến thức',
                reflection.entropyTrend,
                theme,
                colorScheme,
              ),
              const SizedBox(width: 12),
              _buildTrend(
                'Accuracy',
                reflection.accuracyTrend,
                theme,
                colorScheme,
              ),
              const SizedBox(width: 12),
              _buildTrend(
                'Cảm xúc',
                reflection.emotionTrend,
                theme,
                colorScheme,
              ),
            ],
          ),

          // Recommendation
          if (reflection.shouldChangeStrategy &&
              reflection.recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reflection.recommendation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reasoning
          if (reflection.reasoning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reflection.reasoning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEffectivenessBadge(ThemeData theme) {
    final (label, color) = switch (reflection.effectiveness) {
      'effective' => ('Hiệu quả', Colors.green),
      'ineffective' => ('Chưa hiệu quả', Colors.red),
      _ => ('Trung bình', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrend(
    String label,
    String trend,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final (icon, color) = switch (trend) {
      'improving' || 'decreasing' => (Icons.trending_up, Colors.green),
      'declining' ||
      'increasing' ||
      'worsening' => (Icons.trending_down, Colors.red),
      _ => (Icons.trending_flat, Colors.grey),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
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
