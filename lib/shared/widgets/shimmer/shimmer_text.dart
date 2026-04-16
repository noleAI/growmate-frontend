import 'package:flutter/material.dart';

import 'shimmer_loading.dart';

/// Text line placeholder for loading states.
class ShimmerText extends StatelessWidget {
  const ShimmerText({
    super.key,
    this.width = 200,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
