import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: GrowMateColors.primary,
        primary: GrowMateColors.primary,
        onPrimary: Colors.white,
        surface: GrowMateColors.surface,
        onSurface: GrowMateColors.textPrimary,
      ).copyWith(
        primaryContainer: GrowMateColors.primaryContainer,
        secondaryContainer: GrowMateColors.secondaryContainer,
        tertiaryContainer: GrowMateColors.tertiaryContainer,
        onPrimaryContainer: GrowMateColors.textPrimary,
        onSecondaryContainer: GrowMateColors.textPrimary,
        onTertiaryContainer: GrowMateColors.textPrimary,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: GrowMateColors.surfaceContainerLow,
        surfaceContainerHigh: GrowMateColors.surfaceContainerHigh,
        outline: const Color(0xFFE2DFD8),
        outlineVariant: const Color(0xFFE7E4DD),
      );

  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: GrowMateColors.textPrimary,
      displayColor: GrowMateColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: GrowMateColors.background,
      canvasColor: GrowMateColors.background,
      cardColor: colorScheme.surfaceContainerLow,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: GrowMateColors.textPrimary,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          backgroundColor: GrowMateColors.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GrowMateLayout.buttonRadius),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: GrowMateColors.primary, width: 1.25),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.tertiaryContainer,
        disabledColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
