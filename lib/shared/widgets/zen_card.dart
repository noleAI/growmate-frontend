import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';

class AIGlassCard extends StatelessWidget {
  const AIGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = GrowMateLayout.cardRadius,
    this.color,
    this.gradient,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? GrowMateColors.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (margin == null) {
      return card;
    }

    return Padding(padding: margin!, child: card);
  }
}

class ZenCard extends AIGlassCard {
  const ZenCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(22),
    super.radius = GrowMateLayout.cardRadius,
    super.color,
    super.gradient,
    super.margin,
  });
}
