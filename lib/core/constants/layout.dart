import 'package:flutter/material.dart';

class GrowMateLayout {
  GrowMateLayout._();

  static const double maxContentWidth = 640;
  static const double horizontalPadding = 24;
  static const double verticalPadding = 24;

  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double sectionGap = space24;
  static const double sectionGapLg = space32;
  static const double contentGapSm = space12;
  static const double contentGap = space16;

  static const double itemGap = contentGap;
  static const double itemGapSm = space8;
  static const double itemGapMd = contentGap;
  static const double itemGapLg = sectionGap;

  static const double cardRadius = 20;
  static const double buttonRadius = 16;
  static const double specialRadius = 20;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );

  // ── Living Intelligence Layout Tokens ──
  static const double breathSm = 12;
  static const double breath = 20;
  static const double breathLg = 32;
  static const double breathXl = 48;

  static const double cardRadiusLg = 24;
  static const double cardRadiusSm = 16;

  static const EdgeInsets cardPaddingAi = EdgeInsets.fromLTRB(20, 24, 20, 20);

  // AI Orb sizing
  static const double orbSize = 56;
  static const double orbBottomOffset = 80;
  static const double orbRightOffset = 16;
}

/// Consistent elevation levels for cards and surfaces.
class GrowMateElevation {
  GrowMateElevation._();

  static List<BoxShadow> none() => const [];

  static List<BoxShadow> low(ColorScheme colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium(ColorScheme colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> high(ColorScheme colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
