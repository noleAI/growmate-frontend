import 'dart:math';

import 'package:flutter/material.dart';

/// A horizontal shake animation for error states.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeCount = 3,
    this.shakeOffset = 6.0,
  });

  final Widget child;
  final int shakeCount;
  final double shakeOffset;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Call this to trigger the shake animation.
  void shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sineValue = sin(widget.shakeCount * 2 * pi * _controller.value);
        final offset = sineValue * widget.shakeOffset * (1 - _controller.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
