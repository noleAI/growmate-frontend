import 'package:flutter/material.dart';

/// An animated checkmark that draws itself on completion.
class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({
    super.key,
    this.size = 48,
    this.color,
    this.strokeWidth = 3.5,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              progress: _controller.value,
              color: color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Checkmark path: bottom-left to middle-bottom to top-right
    path.moveTo(w * 0.2, h * 0.5);
    path.lineTo(w * 0.42, h * 0.72);
    path.lineTo(w * 0.8, h * 0.28);

    // Draw only the portion based on progress
    final metrics = path.computeMetrics().first;
    final drawPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
