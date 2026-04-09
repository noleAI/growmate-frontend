import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';

class AIGlassCard extends StatelessWidget {
  const AIGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = GrowMateLayout.cardRadius,
    this.color,
    this.gradient,
    this.margin,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? GrowMateColors.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : const [],
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
    super.padding = const EdgeInsets.all(20),
    super.radius = GrowMateLayout.cardRadius,
    super.color,
    super.gradient,
    super.margin,
    super.showShadow,
  });
}
