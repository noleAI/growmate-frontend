import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';

/// AI-enhanced Pomodoro focus timer.
class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  static const _focusDuration = Duration(minutes: 25);
  static const _breakDuration = Duration(minutes: 5);

  Duration _remaining = _focusDuration;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  int _completedSessions = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds <= 0) {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            if (!_isBreak) {
              _completedSessions++;
              _isBreak = true;
              _remaining = _breakDuration;
            } else {
              _isBreak = false;
              _remaining = _focusDuration;
            }
          });
          return;
        }
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      });
      setState(() => _isRunning = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remaining = _focusDuration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _isBreak ? _breakDuration : _focusDuration;
    final progress = 1.0 - (_remaining.inSeconds / total.inSeconds);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleSpacing: 0,
        title: Text(
          context.t(vi: 'Tập trung', en: 'Focus'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Timer circle
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _CircularTimerPainter(
                  progress: progress,
                  color: _isBreak ? Colors.green : theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_remaining),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _isBreak
                            ? context.t(vi: 'Nghỉ ngơi', en: 'Break')
                            : context.t(vi: 'Tập trung', en: 'Focus'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 24),
                FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _isRunning
                        ? context.t(vi: 'Tạm dừng', en: 'Pause')
                        : context.t(vi: 'Bắt đầu', en: 'Start'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),

            // Session counter
            Text(
              context.t(
                vi: 'Phiên hoàn thành: $_completedSessions',
                en: 'Sessions completed: $_completedSessions',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _CircularTimerPainter extends CustomPainter {
  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter old) =>
      old.progress != progress || old.color != color;
}
