import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Full-screen AFK overlay displayed when user is idle > 3 minutes.
///
/// Dims the screen with a gentle message. Dismisses on any tap.
class AfkOverlay extends StatelessWidget {
  const AfkOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onResume,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💤', style: TextStyle(fontSize: 56)),
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
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
