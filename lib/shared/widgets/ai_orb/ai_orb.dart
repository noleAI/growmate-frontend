import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';
import 'ai_orb_state.dart';

/// The floating AI orb – the heart of the Living Intelligence UI.
///
/// It communicates the current AI state via layered animations:
///   - breathing (idle)
///   - ripple rings (thinking)
///   - glow + bounce (hasSuggestion)
///   - amber wobble (uncertain)
///   - celebratory pulse (confident)
///   - static red border (error)
class AiOrb extends StatefulWidget {
  const AiOrb({
    super.key,
    this.state = AiOrbState.idle,
    this.confidence = 0.0,
    this.hasNotification = false,
    required this.onTap,
    this.onLongPress,
    this.size = GrowMateLayout.orbSize,
  });

  final AiOrbState state;
  final double confidence;
  final bool hasNotification;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant AiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncAnimations();
  }

  void _syncAnimations() {
    // Reset non-breath controllers
    _pulseController.stop();
    _bounceController.stop();

    switch (widget.state) {
      case AiOrbState.idle:
      case AiOrbState.error:
        break;
      case AiOrbState.thinking:
        _pulseController.repeat();
      case AiOrbState.hasSuggestion:
        _bounceController.repeat(reverse: true);
      case AiOrbState.uncertain:
        _bounceController.repeat(reverse: true);
      case AiOrbState.confident:
        _pulseController
          ..reset()
          ..forward();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Color _baseColor(Brightness brightness) {
    return switch (widget.state) {
      AiOrbState.uncertain => GrowMateColors.uncertain(brightness),
      AiOrbState.error => GrowMateColors.lowConfidence(brightness),
      _ => GrowMateColors.aiCore(brightness),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final brightness = Theme.of(context).brightness;
    final baseColor = _baseColor(brightness);

    return SizedBox(
      width: s + 16, // Glow padding
      height: s + 16,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breathController,
            _pulseController,
            _bounceController,
          ]),
          builder: (context, child) {
            final breathScale =
                1.0 +
                0.02 * Curves.easeInOut.transform(_breathController.value);

            final bounceOffset = widget.state == AiOrbState.hasSuggestion
                ? 2.0 * math.sin(_bounceController.value * math.pi)
                : 0.0;

            final wobbleAngle = widget.state == AiOrbState.uncertain
                ? 0.04 * math.sin(_bounceController.value * 2 * math.pi)
                : 0.0;

            return Transform.translate(
              offset: Offset(0, -bounceOffset),
              child: Transform.rotate(
                angle: wobbleAngle,
                child: Transform.scale(scale: breathScale, child: child),
              ),
            );
          },
          child: RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow layer
                if (widget.state != AiOrbState.error)
                  Container(
                    width: s + 16,
                    height: s + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          baseColor.withValues(
                            alpha: widget.state == AiOrbState.hasSuggestion
                                ? 0.25
                                : 0.12,
                          ),
                          baseColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),

                // Confidence ring
                if (widget.confidence > 0)
                  SizedBox(
                    width: s + 6,
                    height: s + 6,
                    child: CircularProgressIndicator(
                      value: widget.confidence.clamp(0, 1),
                      strokeWidth: 3,
                      backgroundColor: GrowMateColors.surface2(brightness).withValues(
                        alpha: 0.5,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        GrowMateColors.confidenceColor(widget.confidence, brightness),
                      ),
                    ),
                  ),

                // Pulse rings (thinking)
                if (widget.state == AiOrbState.thinking)
                  _PulseRings(
                    animation: _pulseController,
                    color: baseColor,
                    size: s,
                  ),

                // Core circle
                Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [baseColor, baseColor.withValues(alpha: 0.85)],
                    ),
                    border: widget.state == AiOrbState.error
                        ? Border.all(
                            color: GrowMateColors.lowConfidence(brightness),
                            width: 2.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _iconForState(),
                    color: Colors.white,
                    size: s * 0.42,
                  ),
                ),

                // Notification dot
                if (widget.hasNotification)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GrowMateColors.lowConfidence(brightness),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForState() {
    return switch (widget.state) {
      AiOrbState.thinking => Icons.psychology_rounded,
      AiOrbState.uncertain => Icons.help_outline_rounded,
      AiOrbState.error => Icons.warning_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

class _PulseRings extends StatelessWidget {
  const _PulseRings({
    required this.animation,
    required this.color,
    required this.size,
  });

  final Animation<double> animation;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: CustomPaint(
        painter: _PulseRingPainter(progress: animation.value, color: color),
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    for (var i = 0; i < 2; i++) {
      final offset = (progress + i * 0.5) % 1.0;
      final radius = maxRadius * (0.5 + 0.5 * offset);
      final opacity = (1.0 - offset) * 0.3;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter old) =>
      old.progress != progress;
}
