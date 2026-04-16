import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// Tints the page background based on the current Particle Filter emotional state.
///
/// Wraps its child in an [AnimatedContainer] that subtly shifts background
/// colour over 3 seconds when the emotion changes.
class AmbientGradient extends StatelessWidget {
  const AmbientGradient({
    super.key,
    required this.child,
    this.emotion = 'focused',
  });

  final Widget child;
  final String emotion;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = _tintFor(emotion, brightness);
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    final blended = Color.lerp(baseColor, tint, 0.06) ?? baseColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeInOut,
      color: blended,
      child: child,
    );
  }

  /// Returns the blended background colour for a given [emotion] without
  /// needing a widget wrapper.  Use this to feed `Scaffold.backgroundColor`.
  static Color colorFor(Color baseColor, String emotion, [Brightness brightness = Brightness.light]) {
    final tint = _tintFor(emotion, brightness);
    return Color.lerp(baseColor, tint, 0.06) ?? baseColor;
  }

  static Color _tintFor(String emotion, [Brightness brightness = Brightness.light]) {
    return switch (emotion) {
      'focused' => GrowMateColors.focused(brightness),
      'confused' => GrowMateColors.confused(brightness),
      'exhausted' => GrowMateColors.exhausted(brightness),
      'frustrated' => GrowMateColors.frustrated(brightness),
      _ => GrowMateColors.focused(brightness),
    };
  }
}
