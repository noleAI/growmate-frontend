import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import '../confidence/confidence_arc.dart';
import 'ai_block_base.dart';
import 'ai_block_model.dart';

/// Block Type 1: AI Insight — shows a confident assessment with arc gauge.
class InsightBlockWidget extends StatelessWidget {
  const InsightBlockWidget({super.key, required this.block, this.delayMs = 0});

  final InsightBlock block;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(vi: 'AI nhận định', en: 'AI Insight'),
      accentColor: GrowMateColors.confidenceColor(block.confidence, Theme.of(context).brightness),
      delayMs: delayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence arc (compact)
          Center(
            child: ConfidenceArc(
              confidence: block.confidence,
              size: 88,
              strokeWidth: 5,
              label: context.t(vi: 'tin cậy', en: 'confidence'),
            ),
          ),
          const SizedBox(height: 16),

          // Insight text
          Text(
            block.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),

          // Evidence + freshness
          if (block.evidenceSource != null || block.updatedAgo != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            if (block.evidenceSource != null)
              _MetaRow(
                label: context.t(vi: 'Dựa trên', en: 'Based on'),
                value: block.evidenceSource!,
              ),
            if (block.updatedAgo != null)
              _MetaRow(
                label: context.t(vi: 'Cập nhật', en: 'Updated'),
                value: block.updatedAgo!,
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: style?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
