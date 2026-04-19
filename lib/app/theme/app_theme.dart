import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/layout.dart';
import 'color_palette_cubit.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => lightThemeFor(AppColorPalette.mintCream);

  static ThemeData get darkTheme => darkThemeFor(AppColorPalette.mintCream);

  static ThemeData lightThemeFor(AppColorPalette palette) {
    final colorScheme = _lightColorSchemeFor(palette);

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: _lightScaffoldColorFor(palette),
      buttonShadowColor: _buttonShadowFor(
        palette,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData darkThemeFor(AppColorPalette palette) {
    final colorScheme = _darkColorSchemeFor(palette);

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: colorScheme.surface,
      buttonShadowColor: _buttonShadowFor(palette, brightness: Brightness.dark),
    );
  }

  static ColorScheme _lightColorSchemeFor(AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF2F9A4C),
        ).copyWith(
          primary: const Color(0xFF2F9A4C),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDDF6E3),
          secondary: const Color(0xFF5E5000),
          tertiary: const Color(0xFFD3A425),
          surface: Colors.white,
          onSurface: const Color(0xFF11221A),
          secondaryContainer: const Color(0xFFFFF2CC),
          tertiaryContainer: const Color(0xFFFFF7DC),
          onPrimaryContainer: const Color(0xFF0E2A17),
          onSecondaryContainer: const Color(0xFF3A3000),
          onTertiaryContainer: const Color(0xFF4A3900),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHigh: const Color(0xFFE8F1E6),
          outline: const Color(0xFFC8D3CA),
          outlineVariant: const Color(0xFFDFE8DF),
          shadow: const Color(0x3311221A),
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.blueWhite:
        return ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF4F8CFF),
        ).copyWith(
          primary: const Color(0xFF4F8CFF),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE8F1FF),
          secondary: const Color(0xFF0F172A),
          tertiary: const Color(0xFF20A46B),
          surface: Colors.white,
          onSurface: const Color(0xFF0F1728),
          secondaryContainer: const Color(0xFFF1F4FA),
          tertiaryContainer: const Color(0xFFE2F5EA),
          onPrimaryContainer: const Color(0xFF0F1728),
          onSecondaryContainer: const Color(0xFF0F1728),
          onTertiaryContainer: const Color(0xFF0F1728),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHigh: const Color(0xFFEBF0F7),
          outline: const Color(0xFFD8DEE9),
          outlineVariant: const Color(0xFFECEFF5),
          shadow: const Color(0x330F172A),
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.sunsetPeach:
        return ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFFE76F51),
        ).copyWith(
          primary: const Color(0xFFE76F51),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFFFE5DE),
          secondary: const Color(0xFF7A3E2E),
          tertiary: const Color(0xFFF4A261),
          surface: Colors.white,
          onSurface: const Color(0xFF2A1915),
          secondaryContainer: const Color(0xFFFFEEE7),
          tertiaryContainer: const Color(0xFFFFF1DF),
          onPrimaryContainer: const Color(0xFF3B170E),
          onSecondaryContainer: const Color(0xFF3D2018),
          onTertiaryContainer: const Color(0xFF50340A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHigh: const Color(0xFFF9ECE7),
          outline: const Color(0xFFE8CBC2),
          outlineVariant: const Color(0xFFF2DED8),
          shadow: const Color(0x332A1915),
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.mintCream:
        return ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF2DAA90),
        ).copyWith(
          primary: const Color(0xFF2DAA90),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDDF7EF),
          secondary: const Color(0xFF0F5256),
          tertiary: const Color(0xFF59B7B1),
          surface: Colors.white,
          onSurface: const Color(0xFF102122),
          secondaryContainer: const Color(0xFFE8F6F6),
          tertiaryContainer: const Color(0xFFE5F8F4),
          onPrimaryContainer: const Color(0xFF0C2F2A),
          onSecondaryContainer: const Color(0xFF113739),
          onTertiaryContainer: const Color(0xFF11373A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHigh: const Color(0xFFEAF4F2),
          outline: const Color(0xFFC7DDD8),
          outlineVariant: const Color(0xFFDCEBE7),
          shadow: const Color(0x33102122),
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.oceanSlate:
        return ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF2B6EA6),
        ).copyWith(
          primary: const Color(0xFF2B6EA6),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDCEEFF),
          secondary: const Color(0xFF25445B),
          tertiary: const Color(0xFF1E9AA0),
          surface: Colors.white,
          onSurface: const Color(0xFF0E1A25),
          secondaryContainer: const Color(0xFFE8F0F8),
          tertiaryContainer: const Color(0xFFE2F6F7),
          onPrimaryContainer: const Color(0xFF0C2942),
          onSecondaryContainer: const Color(0xFF173347),
          onTertiaryContainer: const Color(0xFF0F383B),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHigh: const Color(0xFFE9EEF3),
          outline: const Color(0xFFCBD8E3),
          outlineVariant: const Color(0xFFDEE7EF),
          shadow: const Color(0x330E1A25),
          surfaceTint: Colors.transparent,
        );
    }
  }

  static ColorScheme _darkColorSchemeFor(AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF68C77D),
        ).copyWith(
          primary: const Color(0xFF86D79A),
          onPrimary: const Color(0xFF093017),
          primaryContainer: const Color(0xFF1F5C2F),
          secondary: const Color(0xFFFFDD7A),
          tertiary: const Color(0xFFF8CF65),
          surface: const Color(0xFF101A12),
          onSurface: const Color(0xFFE8F2E8),
          secondaryContainer: const Color(0xFF4B3D00),
          tertiaryContainer: const Color(0xFF564400),
          onPrimaryContainer: const Color(0xFFCFF2D8),
          onSecondaryContainer: const Color(0xFFFFECB5),
          onTertiaryContainer: const Color(0xFFFFEEB8),
          surfaceContainerLowest: const Color(0xFF0A120C),
          surfaceContainerLow: const Color(0xFF17251B),
          surfaceContainerHigh: const Color(0xFF213126),
          outline: const Color(0xFF3E5443),
          outlineVariant: const Color(0xFF2F4335),
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.blueWhite:
        return ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF7DA9FF),
        ).copyWith(
          primary: const Color(0xFF8DB4FF),
          onPrimary: const Color(0xFF0A1A37),
          primaryContainer: const Color(0xFF1F3460),
          secondary: const Color(0xFFC5D7FF),
          tertiary: const Color(0xFF5FD2A1),
          surface: const Color(0xFF0F1628),
          onSurface: const Color(0xFFE8EDF8),
          secondaryContainer: const Color(0xFF1A2640),
          tertiaryContainer: const Color(0xFF173428),
          onPrimaryContainer: const Color(0xFFDCE8FF),
          onSecondaryContainer: const Color(0xFFD6DFF2),
          onTertiaryContainer: const Color(0xFFCEEEDD),
          surfaceContainerLowest: const Color(0xFF090E1A),
          surfaceContainerLow: const Color(0xFF151E31),
          surfaceContainerHigh: const Color(0xFF202A40),
          outline: const Color(0xFF3B4968),
          outlineVariant: const Color(0xFF2D3953),
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.sunsetPeach:
        return ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFFF9B83),
        ).copyWith(
          primary: const Color(0xFFFFA891),
          onPrimary: const Color(0xFF4B1E14),
          primaryContainer: const Color(0xFF6A2E22),
          secondary: const Color(0xFFFFC9B6),
          tertiary: const Color(0xFFFFCF92),
          surface: const Color(0xFF1E1412),
          onSurface: const Color(0xFFF7EAE4),
          secondaryContainer: const Color(0xFF5C3329),
          tertiaryContainer: const Color(0xFF624519),
          onPrimaryContainer: const Color(0xFFFFE4DA),
          onSecondaryContainer: const Color(0xFFFFE2D5),
          onTertiaryContainer: const Color(0xFFFFE9C7),
          surfaceContainerLowest: const Color(0xFF140D0C),
          surfaceContainerLow: const Color(0xFF271A17),
          surfaceContainerHigh: const Color(0xFF32221E),
          outline: const Color(0xFF6A4C45),
          outlineVariant: const Color(0xFF533B36),
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.mintCream:
        return ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF67D0B8),
        ).copyWith(
          primary: const Color(0xFF74D7C1),
          onPrimary: const Color(0xFF0D3A33),
          primaryContainer: const Color(0xFF1D5A50),
          secondary: const Color(0xFFB6ECE2),
          tertiary: const Color(0xFF8FDFDC),
          surface: const Color(0xFF0F1C1B),
          onSurface: const Color(0xFFE5F2F0),
          secondaryContainer: const Color(0xFF234844),
          tertiaryContainer: const Color(0xFF214746),
          onPrimaryContainer: const Color(0xFFD2F4EC),
          onSecondaryContainer: const Color(0xFFD0F1EB),
          onTertiaryContainer: const Color(0xFFD5F4F2),
          surfaceContainerLowest: const Color(0xFF091211),
          surfaceContainerLow: const Color(0xFF152726),
          surfaceContainerHigh: const Color(0xFF203535),
          outline: const Color(0xFF3E5957),
          outlineVariant: const Color(0xFF304746),
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        );
      case AppColorPalette.oceanSlate:
        return ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF6CB5F0),
        ).copyWith(
          primary: const Color(0xFF7CC0F6),
          onPrimary: const Color(0xFF0E2A41),
          primaryContainer: const Color(0xFF1C4468),
          secondary: const Color(0xFFC9DDF2),
          tertiary: const Color(0xFF89E0E3),
          surface: const Color(0xFF0E1822),
          onSurface: const Color(0xFFE6EDF5),
          secondaryContainer: const Color(0xFF21374B),
          tertiaryContainer: const Color(0xFF1B4345),
          onPrimaryContainer: const Color(0xFFD5E9F9),
          onSecondaryContainer: const Color(0xFFD6E5F4),
          onTertiaryContainer: const Color(0xFFD4F3F4),
          surfaceContainerLowest: const Color(0xFF080F16),
          surfaceContainerLow: const Color(0xFF141F2C),
          surfaceContainerHigh: const Color(0xFF1E2B3A),
          outline: const Color(0xFF42596E),
          outlineVariant: const Color(0xFF33475A),
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        );
    }
  }

  static Color _lightScaffoldColorFor(AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return const Color(0xFFF6FAF4);
      case AppColorPalette.blueWhite:
        return const Color(0xFFF5F7FB);
      case AppColorPalette.sunsetPeach:
        return const Color(0xFFFFF7F4);
      case AppColorPalette.mintCream:
        return const Color(0xFFF4FAF8);
      case AppColorPalette.oceanSlate:
        return const Color(0xFFF3F7FA);
    }
  }

  static Color _buttonShadowFor(
    AppColorPalette palette, {
    required Brightness brightness,
  }) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return brightness == Brightness.dark
            ? const Color.fromRGBO(134, 215, 154, 0.2)
            : const Color.fromRGBO(47, 154, 76, 0.2);
      case AppColorPalette.blueWhite:
        return brightness == Brightness.dark
            ? const Color.fromRGBO(141, 180, 255, 0.24)
            : const Color.fromRGBO(79, 140, 255, 0.18);
      case AppColorPalette.sunsetPeach:
        return brightness == Brightness.dark
            ? const Color.fromRGBO(255, 168, 145, 0.24)
            : const Color.fromRGBO(231, 111, 81, 0.18);
      case AppColorPalette.mintCream:
        return brightness == Brightness.dark
            ? const Color.fromRGBO(116, 215, 193, 0.24)
            : const Color.fromRGBO(45, 170, 144, 0.18);
      case AppColorPalette.oceanSlate:
        return brightness == Brightness.dark
            ? const Color.fromRGBO(124, 192, 246, 0.24)
            : const Color.fromRGBO(43, 110, 166, 0.18);
    }
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return GoogleFonts.plusJakartaSansTextTheme()
        .apply(bodyColor: baseColor, displayColor: baseColor)
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
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldColor,
    required Color buttonShadowColor,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface);
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: scaffoldColor,
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
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
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
        shadowColor: isDark ? const Color(0x2D000000) : const Color(0x0D0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              backgroundColor: colorScheme.primary,
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
              shadowColor: buttonShadowColor,
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.12),
              ),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.onSurface,
          foregroundColor: colorScheme.surface,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GrowMateLayout.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outlineVariant),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GrowMateLayout.buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 1.25),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
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
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primary.withValues(
          alpha: isDark ? 0.2 : 0.1,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
    );
  }
}
