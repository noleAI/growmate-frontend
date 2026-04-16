import 'package:flutter/material.dart';

/// Animation tim vỡ khi user mất 1 tim.
///
/// Dùng với AnimationController — gọi forward() khi mất tim.
class HeartBreakAnimation extends StatefulWidget {
  const HeartBreakAnimation({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<HeartBreakAnimation> createState() => _HeartBreakAnimationState();
}

class _HeartBreakAnimationState extends State<HeartBreakAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value.clamp(0.0, 1.0),
            child: const Text('💔', style: TextStyle(fontSize: 48)),
          ),
        );
      },
    );
  }
}
