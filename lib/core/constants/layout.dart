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
}
