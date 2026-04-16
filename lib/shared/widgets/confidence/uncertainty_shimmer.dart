import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// Overlays a subtle horizontal shimmer on its child when AI uncertainty is
/// above a threshold. The shimmer intensity scales with the uncertainty value.
class UncertaintyShimmer extends StatefulWidget {
  const UncertaintyShimmer({
    super.key,
    required this.child,
    required this.uncertainty,
    this.threshold = 0.2,
    this.duration = const Duration(milliseconds: 2000),
  });

  final Widget child;
  final double uncertainty;
  final double threshold;
  final Duration duration;

  @override
  State<UncertaintyShimmer> createState() => _UncertaintyShimmerState();
}

class _UncertaintyShimmerState extends State<UncertaintyShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool get _active => widget.uncertainty > widget.threshold;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (_active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant UncertaintyShimmer old) {
    super.didUpdateWidget(old);
    if (_active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;

    final brightness = Theme.of(context).brightness;
    final intensity =
        ((widget.uncertainty - widget.threshold) / (1 - widget.threshold))
            .clamp(0.0, 1.0);
    final shimmerColor = GrowMateColors.uncertain(brightness).withValues(
      alpha: 0.08 * intensity,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-0.5 + 2.0 * _controller.value, 0),
              colors: [Colors.white, shimmerColor, Colors.white],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}
