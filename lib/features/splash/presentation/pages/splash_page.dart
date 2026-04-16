import 'dart:async';

import 'package:flutter/material.dart';

/// Animated splash screen with logo scale + app name typewriter effect + tagline.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _taglineController;
  late final AnimationController _shimmerController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;

  static const String _appName = 'GrowMate';
  static const String _tagline = 'Học thông minh — Thi tự tin';
  int _visibleChars = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // Shimmer animation for logo ring
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoController.forward();

    // Start typewriter after logo animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _textController.forward();
      _typewriterTimer = Timer.periodic(const Duration(milliseconds: 70), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _visibleChars += 1;
        });
        if (_visibleChars >= _appName.length) {
          timer.cancel();
          // Show tagline after name completes
          _taglineController.forward();
        }
      });
    });

    // Auto-navigate after 2s
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.12),
              colors.surface,
              colors.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with shimmer ring
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(scale: _logoScale.value, child: child),
                );
              },
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        startAngle: _shimmerController.value * 6.28,
                        colors: [
                          colors.primary.withValues(alpha: 0.15),
                          colors.primary.withValues(alpha: 0.4),
                          colors.primary.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: child,
                  );
                },
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.primaryContainer,
                        colors.primaryContainer.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.2),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.energy_savings_leaf_rounded,
                    size: 52,
                    color: colors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // App name typewriter
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                _appName.substring(0, _visibleChars.clamp(0, _appName.length)),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: colors.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tagline
            AnimatedBuilder(
              animation: _taglineController,
              builder: (context, child) {
                return Opacity(
                  opacity: _taglineOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _taglineSlide.value),
                    child: child,
                  ),
                );
              },
              child: Text(
                _tagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
