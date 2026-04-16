import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/layout.dart';

/// A popup dialog celebrating a daily login streak with animations.
class StreakPopup extends StatefulWidget {
  const StreakPopup({
    super.key,
    required this.streakDays,
    required this.xpBonus,
    this.weekDays = const [true, true, true, false, false, false, false],
  });

  final int streakDays;
  final int xpBonus;

  /// 7 booleans for Mon-Sun, true = completed.
  final List<bool> weekDays;

  static Future<void> show(
    BuildContext context, {
    required int streakDays,
    required int xpBonus,
    List<bool> weekDays = const [true, true, true, false, false, false, false],
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => StreakPopup(
        streakDays: streakDays,
        xpBonus: xpBonus,
        weekDays: weekDays,
      ),
    );
  }

  @override
  State<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends State<StreakPopup>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _confettiController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeIn));

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _enterController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _motivationalMessage(BuildContext context) {
    if (widget.streakDays >= 30) {
      return context.t(
        vi: 'Kiên trì tuyệt vời! Bạn là chiến binh học tập! 🏆',
        en: 'Incredible perseverance! You\'re a learning champion! 🏆',
      );
    } else if (widget.streakDays >= 14) {
      return context.t(
        vi: 'Ấn tượng! Thói quen đã hình thành rồi! 🌟',
        en: 'Impressive! The habit is forming! 🌟',
      );
    } else if (widget.streakDays >= 7) {
      return context.t(
        vi: 'Một tuần rồi đó! Tiếp tục nào! 💪',
        en: 'One week strong! Keep going! 💪',
      );
    } else if (widget.streakDays >= 3) {
      return context.t(
        vi: 'Khởi đầu tốt lắm! Đừng dừng lại nhé!',
        en: 'Great start! Don\'t stop now!',
      );
    }
    return context.t(
      vi: 'Mỗi ngày một bước, bạn sẽ tiến xa!',
      en: 'One step each day, you\'ll go far!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Confetti overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ConfettiPainter(
                            progress: _confettiController.value,
                            colors: [
                              Colors.amber,
                              colors.primary,
                              Colors.orange,
                              colors.tertiary,
                              Colors.pink.shade300,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated fire
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: const Text('🔥', style: TextStyle(fontSize: 56)),
                      ),
                      const SizedBox(height: GrowMateLayout.space12),
                      Text(
                        context.t(
                          vi: '${widget.streakDays} ngày liên tiếp!',
                          en: '${widget.streakDays} day streak!',
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.orange.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '+${widget.xpBonus} XP',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Motivational message
                      Text(
                        _motivationalMessage(context),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: GrowMateLayout.sectionGap),

                      // Week calendar
                      _WeekCalendar(weekDays: widget.weekDays),

                      const SizedBox(height: GrowMateLayout.sectionGap),

                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.t(vi: 'Tuyệt vời! 🎉', en: 'Awesome! 🎉'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints falling confetti-like particles.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;
  static const _count = 24;

  // Pre-compute particle positions using seed
  static final _particles = List.generate(_count, (i) {
    final r = math.Random(42 + i);
    return (
      x: r.nextDouble(),
      startY: -0.1 - r.nextDouble() * 0.3,
      speed: 0.6 + r.nextDouble() * 0.6,
      size: 4.0 + r.nextDouble() * 4,
      rotation: r.nextDouble() * math.pi,
      colorIndex: r.nextInt(5),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    for (final p in _particles) {
      final y = p.startY + progress * p.speed;
      if (y < -0.1 || y > 1.0) continue;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[p.colorIndex].withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;

      final dx = p.x * size.width;
      final dy = y * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + progress * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({required this.weekDays});

  final List<bool> weekDays;

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final done = index < weekDays.length && weekDays[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? colors.primary : colors.surfaceContainerHigh,
              ),
              child: Center(
                child: done
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dayLabels[index],
              style: theme.textTheme.labelSmall?.copyWith(
                color: done ? colors.primary : colors.onSurfaceVariant,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}
