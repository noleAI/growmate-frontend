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
        outline: const Color(0xFFD8DEE9),
        outlineVariant: const Color(0xFFECEFF5),
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
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.42,
            height: 1.06,
          ),
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.28,
            height: 1.08,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.22,
            height: 1.1,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.14,
            height: 1.2,
          ),
          titleMedium: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.04,
            height: 1.24,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
        shadowColor: const Color(0x0D0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              backgroundColor: GrowMateColors.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  GrowMateLayout.buttonRadius,
                ),
              ),
              textStyle: textTheme.labelLarge?.copyWith(
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
        fillColor: GrowMateColors.surfaceContainerLow,
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
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        indicatorColor: GrowMateColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
    );
  }
}
