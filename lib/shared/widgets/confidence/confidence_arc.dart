import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// A circular arc gauge that visualises AI confidence (0.0 – 1.0).
///
/// The arc sweeps clockwise from the top. Colors interpolate through the
/// confidence spectrum: red → amber → teal → green.
class ConfidenceArc extends StatefulWidget {
  const ConfidenceArc({
    super.key,
    required this.confidence,
    this.uncertainty = 0.0,
    this.label,
    this.sublabel,
    this.size = 120,
    this.strokeWidth = 6,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final double confidence;
  final double uncertainty;
  final String? label;
  final String? sublabel;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;

  @override
  State<ConfidenceArc> createState() => _ConfidenceArcState();
}

class _ConfidenceArcState extends State<ConfidenceArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.confidence.clamp(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfidenceArc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.confidence - widget.confidence).abs() > 0.01) {
      _previousValue = _animation.value;
      _animation =
          Tween<double>(
            begin: _previousValue,
            end: widget.confidence.clamp(0, 1),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final pct = (widget.confidence.clamp(0.0, 1.0) * 100).toStringAsFixed(0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ArcPainter(
              value: _animation.value,
              uncertainty: widget.uncertainty.clamp(0, 1),
              strokeWidth: widget.strokeWidth,
              trackColor: theme.colorScheme.surfaceContainerHigh,
              brightness: brightness,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: widget.size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: GrowMateColors.confidenceColor(widget.confidence, brightness),
                  letterSpacing: -0.5,
                ),
              ),
              if (widget.label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.label!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.size * 0.09,
                    ),
                  ),
                ),
              if (widget.sublabel != null)
                Text(
                  widget.sublabel!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: widget.size * 0.075,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.uncertainty,
    required this.strokeWidth,
    required this.trackColor,
    this.brightness = Brightness.light,
  });

  final double value;
  final double uncertainty;
  final double strokeWidth;
  final Color trackColor;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2; // 12 o'clock
    const fullSweep = 2 * math.pi * 0.75; // 270° arc

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, fullSweep, false, trackPaint);

    // Value arc
    if (value > 0) {
      final sweepAngle = fullSweep * value;
      final arcColor = GrowMateColors.confidenceColor(value, brightness);
      final valuePaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, valuePaint);
    }

    // Uncertainty dashes at the end of filled arc
    if (uncertainty > 0.15 && value > 0) {
      final dashStart = startAngle + fullSweep * value;
      final dashSweep = fullSweep * uncertainty.clamp(0, 1 - value) * 0.5;
      if (dashSweep > 0.01) {
        final dashPaint = Paint()
          ..color = GrowMateColors.uncertain(brightness).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.6
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, dashStart, dashSweep, false, dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) {
    return (old.value - value).abs() > 0.005 ||
        (old.uncertainty - uncertainty).abs() > 0.01;
  }
}
