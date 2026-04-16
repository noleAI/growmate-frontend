import 'package:flutter/material.dart';

import '../../../core/constants/layout.dart';
import 'shimmer_loading.dart';

/// Card placeholder skeleton for loading states.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 120, this.width, this.radius});

  final double height;
  final double? width;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ShimmerLoading(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(
            radius ?? GrowMateLayout.cardRadius,
          ),
        ),
      ),
    );
  }
}
