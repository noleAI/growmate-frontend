import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// A small tappable "AI↗" badge placed next to content that was AI-generated.
///
/// Tapping it triggers [onTap] — typically to show a reasoning block or
/// AI Companion sheet explaining *why* AI made this decision.
///
/// Usage:
/// ```dart
/// Row(children: [
///   Text('Đạo hàm hàm hợp'),
///   const SizedBox(width: 6),
///   DecisionBadge(onTap: () => _openWhyReasoning()),
/// ])
/// ```
class DecisionBadge extends StatefulWidget {
  const DecisionBadge({
    super.key,
    required this.onTap,
    this.label = 'AI↗',
    this.pulse = false,
  });

  final VoidCallback onTap;
  final String label;

  /// When true, the badge pulses to draw attention to a new AI decision.
  final bool pulse;

  @override
  State<DecisionBadge> createState() => _DecisionBadgeState();
}

class _DecisionBadgeState extends State<DecisionBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DecisionBadge old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: GrowMateColors.aiWhisper(brightness),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: GrowMateColors.aiCore(brightness).withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: GrowMateColors.aiCore(brightness),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
