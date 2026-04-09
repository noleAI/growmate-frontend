import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';

class ZenCard extends StatelessWidget {
  const ZenCard({
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
        color: color ?? GrowMateColors.surfaceContainerLow,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 64, 74, 0.12),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.5),
            blurRadius: 10,
            offset: Offset(0, -2),
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
