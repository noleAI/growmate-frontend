import 'package:flutter/material.dart';

import '../../data/models/agentic_models.dart' as agentic;

/// Timeline widget hiển thị các bước reasoning của AI.
class AiReasoningTraceWidget extends StatefulWidget {
  const AiReasoningTraceWidget({
    super.key,
    required this.steps,
    required this.conclusion,
    required this.confidence,
    this.isExpanded = false,
  });

  final List<agentic.ReasoningStep> steps;
  final String conclusion;
  final double confidence;
  final bool isExpanded;

  @override
  State<AiReasoningTraceWidget> createState() => _AiReasoningTraceWidgetState();
}

class _AiReasoningTraceWidgetState extends State<AiReasoningTraceWidget> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI đã suy luận qua ${widget.steps.length} bước',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _confidenceColor(
                        widget.confidence,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(widget.confidence * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _confidenceColor(widget.confidence),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Conclusion — always visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.conclusion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
          ),

          // Steps timeline — only when expanded
          if (_expanded) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: widget.steps
                    .map((step) => _buildStep(step, theme, colorScheme))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep(
    agentic.ReasoningStep step,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Text(step.toolIcon, style: const TextStyle(fontSize: 16)),
                if (step.step < widget.steps.length)
                  Container(
                    width: 1,
                    height: 16,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.toolLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (step.resultSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.resultSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
