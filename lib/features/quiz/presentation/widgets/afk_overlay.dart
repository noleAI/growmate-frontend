import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Full-screen AFK overlay displayed when user is idle > 3 minutes.
///
/// Fades in with [AnimatedOpacity] and shows a sleeping mascot.
/// Dismisses on any tap.
class AfkOverlay extends StatefulWidget {
  const AfkOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  State<AfkOverlay> createState() => _AfkOverlayState();
}

class _AfkOverlayState extends State<AfkOverlay> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeIn,
      child: GestureDetector(
        onTap: widget.onResume,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.70),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sleeping mascot
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: const Text('😴', style: TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 16),
              Text(
                context.t(vi: 'Vẫn ở đây không?', en: 'Still here?'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t(vi: 'Nhấn để tiếp tục', en: 'Tap to continue'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
