import 'package:flutter/material.dart';

import '../../data/models/formula_category.dart';
import 'formula_detail_card.dart';
import 'mastery_indicator.dart';

/// Card đại diện cho một nhóm công thức, có thể mở rộng để xem items.
class FormulaCategoryCard extends StatefulWidget {
  const FormulaCategoryCard({
    super.key,
    required this.category,
    this.accuracyByFormulaId = const {},
    this.initiallyExpanded = false,
  });

  final FormulaCategory category;

  /// Bản đồ formulaId → accuracy [0,1]
  final Map<String, double> accuracyByFormulaId;

  final bool initiallyExpanded;

  @override
  State<FormulaCategoryCard> createState() => _FormulaCategoryCardState();
}

class _FormulaCategoryCardState extends State<FormulaCategoryCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  double get _overallAccuracy {
    final values = widget.category.formulas
        .map((f) => widget.accuracyByFormulaId[f.id])
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cat = widget.category;
    final overall = _overallAccuracy;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon bubble
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(cat.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  // Name + count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.formulaCount} công thức',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mastery indicator + chevron
                  MasteryIndicator(
                    accuracy: widget.accuracyByFormulaId.isEmpty
                        ? null
                        : overall,
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0.0,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          // Progress bar
          if (widget.accuracyByFormulaId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: overall,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ),
          // Formulas
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 8),
                ...cat.formulas.map(
                  (f) => FormulaDetailCard(
                    formula: f,
                    accuracy: widget.accuracyByFormulaId[f.id],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}
