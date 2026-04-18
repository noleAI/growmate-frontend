import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../data/models/formula.dart';
import 'mastery_indicator.dart';

/// Card hiển thị chi tiết một công thức – có thể mở rộng để xem ví dụ.
class FormulaDetailCard extends StatefulWidget {
  const FormulaDetailCard({
    super.key,
    required this.formula,
    this.accuracy,
    this.initiallyExpanded = false,
  });

  final Formula formula;

  /// Độ chính xác [0,1] – null nếu chưa làm
  final double? accuracy;

  final bool initiallyExpanded;

  @override
  State<FormulaDetailCard> createState() => _FormulaDetailCardState();
}

class _FormulaDetailCardState extends State<FormulaDetailCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _rotateCtrl;

  bool _looksLikeLatex(String input) {
    final text = input.trim();
    if (text.isEmpty) return false;
    return text.contains(r'\') ||
        text.contains('^') ||
        text.contains('_') ||
        text.contains('{') ||
        text.contains('}') ||
        text.contains('=') ||
        text.contains('(') ||
        text.contains(')');
  }

  Widget _buildFormulaTitle(BuildContext context, String latexOrText) {
    if (!_looksLikeLatex(latexOrText)) {
      return Text(
        latexOrText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      );
    }

    return Math.tex(
      latexOrText,
      mathStyle: MathStyle.display,
      textStyle: const TextStyle(fontSize: 18),
      onErrorFallback: (e) => Text(
        latexOrText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildExampleValue(BuildContext context, Formula formula) {
    final exampleLatex = formula.exampleLatex?.trim();
    if (exampleLatex != null && exampleLatex.isNotEmpty) {
      return Math.tex(
        exampleLatex,
        mathStyle: MathStyle.text,
        textStyle: const TextStyle(fontSize: 15),
        onErrorFallback: (e) => Text(exampleLatex),
      );
    }

    final exampleText = formula.example?.trim();
    if (exampleText != null && exampleText.isNotEmpty) {
      return Text(exampleText);
    }

    return const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 0.5 : 0.0,
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _rotateCtrl.forward();
    } else {
      _rotateCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final f = widget.formula;
    final title = f.title?.trim();
    final effectiveAccuracy = widget.accuracy ?? f.masteryAccuracy;
    final hasExample =
        (f.exampleLatex?.trim().isNotEmpty ?? false) ||
        (f.example?.trim().isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: hasExample ? _toggle : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildFormulaTitle(context, f.latex)),
                  const SizedBox(width: 8),
                  MasteryIndicator(accuracy: effectiveAccuracy, compact: true),
                  if (hasExample) ...[
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_rotateCtrl),
                      child: const Icon(Icons.expand_more_rounded, size: 20),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                f.explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              // Expanded example
              if (_expanded && hasExample) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  'Ví dụ:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildExampleValue(context, f),
                if (f.exampleExplanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    f.exampleExplanation!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              // Difficulty badge
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _DifficultyChip(difficulty: f.difficulty),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      'hard' => (Colors.redAccent, 'Khó'),
      'medium' => (Colors.orange, 'Trung bình'),
      _ => (Colors.green, 'Dễ'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
