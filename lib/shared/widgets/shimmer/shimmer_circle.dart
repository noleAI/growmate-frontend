import 'package:flutter/material.dart';

import 'shimmer_loading.dart';

/// Circle placeholder for loading states (e.g., avatar, icon containers).
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
