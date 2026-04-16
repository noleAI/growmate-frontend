import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';

/// A small text label that describes the confidence level in human-readable form.
class ConfidenceLabel extends StatelessWidget {
  const ConfidenceLabel({
    super.key,
    required this.confidence,
    this.style,
    this.showPercentage = true,
  });

  final double confidence;
  final TextStyle? style;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final safe = confidence.clamp(0.0, 1.0);
    final brightness = Theme.of(context).brightness;
    final pct = (safe * 100).toStringAsFixed(0);
    final label = context.isEnglish
        ? GrowMateColors.confidenceLabelEn(safe)
        : GrowMateColors.confidenceLabelVi(safe);
    final text = showPercentage ? '$label · $pct%' : label;

    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
        color: GrowMateColors.confidenceColor(safe, brightness),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
