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
      ).copyWith(
        primary: GrowMateColors.primary,
        onPrimary: Colors.white,
        primaryContainer: GrowMateColors.primaryContainer,
        secondary: const Color(0xFF0F172A),
        tertiary: GrowMateColors.success,
        surface: GrowMateColors.surface,
        onSurface: GrowMateColors.textPrimary,
        secondaryContainer: GrowMateColors.secondaryContainer,
        tertiaryContainer: GrowMateColors.tertiaryContainer,
        onPrimaryContainer: GrowMateColors.textPrimary,
        onSecondaryContainer: GrowMateColors.textPrimary,
        onTertiaryContainer: GrowMateColors.textPrimary,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: GrowMateColors.surfaceContainerLow,
        surfaceContainerHigh: GrowMateColors.surfaceContainerHigh,
        outline: const Color(0xFFD1D5DB),
        outlineVariant: const Color(0xFFE5E7EB),
        shadow: const Color(0x330F172A),
        surfaceTint: Colors.transparent,
      );

  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme()
        .apply(
          bodyColor: GrowMateColors.textPrimary,
          displayColor: GrowMateColors.textPrimary,
        )
        .copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.08,
          ),
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.12,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.18,
          ),
          titleMedium: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.2,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.2,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: GrowMateColors.background,
      canvasColor: GrowMateColors.background,
      cardColor: colorScheme.surfaceContainerLow,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GrowMateColors.background,
        foregroundColor: GrowMateColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        elevation: 0,
        shadowColor: const Color(0x220F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              backgroundColor: GrowMateColors.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  GrowMateLayout.buttonRadius,
                ),
              ),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              shadowColor: GrowMateColors.shadowButton,
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.12),
              ),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GrowMateColors.textPrimary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GrowMateLayout.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GrowMateColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
          borderSide: BorderSide(color: GrowMateColors.primary, width: 1.25),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: GrowMateColors.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.tertiaryContainer,
        disabledColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GrowMateColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: GrowMateColors.surface,
        indicatorColor: GrowMateColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
    );
  }
}
