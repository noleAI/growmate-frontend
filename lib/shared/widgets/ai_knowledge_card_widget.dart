import 'package:flutter/material.dart';

import '../../data/models/agentic_models.dart';

/// Card hiển thị kiến thức từ SGK/công thức được RAG truy vấn.
class AiKnowledgeCardWidget extends StatelessWidget {
  const AiKnowledgeCardWidget({
    super.key,
    required this.chunks,
    this.query = '',
  });

  final List<KnowledgeChunk> chunks;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kiến thức liên quan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chunks
          ...chunks.map((chunk) => _buildChunk(chunk, theme, colorScheme)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChunk(
    KnowledgeChunk chunk,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _sourceColor(chunk.source).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    chunk.sourceLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _sourceColor(chunk.source),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (chunk.chapter.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    chunk.chapter,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Content
            Text(
              chunk.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sourceColor(String source) {
    return switch (source) {
      'sgk_toan_12' => Colors.blue,
      'cong_thuc' => Colors.teal,
      'bai_giai_mau' => Colors.orange,
      'loi_thuong_gap' => Colors.red,
      _ => Colors.grey,
    };
  }
}
