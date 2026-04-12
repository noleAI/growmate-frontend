import 'package:flutter/material.dart';

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
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
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
    super.border,
  });
}
