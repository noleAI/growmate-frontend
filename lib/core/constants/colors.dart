import 'package:flutter/material.dart';

class GrowMateColors {
  GrowMateColors._();

  static const Color primary = Color(0xFF2DAA90);
  static const Color primaryDark = Color(0xFF238A74);

  static const Color background = Color(0xFFF4FAF8);
  static const Color backgroundSoft = Color(0xFFF9FCFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFEAF4F2);

  static const Color primaryContainer = Color(0xFFDDF7EF);
  static const Color secondaryContainer = Color(0xFFE8F6F6);
  static const Color tertiaryContainer = Color(0xFFE5F8F4);

  static const Color textPrimary = Color(0xFF1A2E2B);
  static const Color textSecondary = Color(0xFF5F736E);

  static const Color success = Color(0xFF1E8E5B);
  static const Color warningSoft = Color(0xFFD9A82E);
  static const Color danger = Color(0xFFE0524D);

  static const Color shadowSoft = Color.fromRGBO(16, 33, 34, 0.04);
  static const Color shadowButton = Color.fromRGBO(45, 170, 144, 0.12);

  // ── Living Intelligence Color System ──
  // Adaptive colors — use these methods instead of raw constants in UI code.

  // AI Intelligence Spectrum (adaptive)
  static Color aiCore([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF5FDBB8)
          : const Color(0xFF1A8A72);

  static Color aiGlow([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF4AC8A4)
          : const Color(0xFF2DAA90);

  static Color aiWhisper([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF1A2E2B)
          : const Color(0xFFE8F7F3);

  static Color aiPulse([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF33E8BE)
          : const Color(0xFF00D4AA);

  // Emotional Spectrum (Particle Filter states) — adaptive
  static Color focused([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF5FDBB8)
          : const Color(0xFF1A8A72);

  static Color confused([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFFF0C060)
          : const Color(0xFFE8A838);

  static Color exhausted([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFFE88888)
          : const Color(0xFFD06060);

  static Color frustrated([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFFE0A060)
          : const Color(0xFFC87830);

  // Surface System (adaptive)
  static Color surface0([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF0F1A16)
          : const Color(0xFFF6FAF9);

  static Color surface1([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF162420)
          : const Color(0xFFFFFFFF);

  static Color surface2([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF1E302A)
          : const Color(0xFFEEF5F3);

  static Color surface3([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF263C34)
          : const Color(0xFFE4EFEC);

  // Confidence Semantic (adaptive)
  static Color confident([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFF5FDBB8)
          : const Color(0xFF1A8A72);

  static Color uncertain([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFFF0C060)
          : const Color(0xFFE8A838);

  static Color lowConfidence([Brightness brightness = Brightness.light]) =>
      brightness == Brightness.dark
          ? const Color(0xFFE88888)
          : const Color(0xFFD06060);

  /// Returns a color for the given confidence value (0.0 – 1.0).
  static Color confidenceColor(
    double value, [
    Brightness brightness = Brightness.light,
  ]) {
    if (value >= 0.8) return confident(brightness);
    if (value >= 0.5) return uncertain(brightness);
    return lowConfidence(brightness);
  }

  /// Returns a Vietnamese label for the given confidence value.
  static String confidenceLabelVi(double value) {
    if (value >= 0.95) return 'AI rất tự tin';
    if (value >= 0.8) return 'AI khá tự tin';
    if (value >= 0.5) return 'AI đang tìm hiểu thêm';
    return 'AI chưa chắc chắn';
  }

  /// Returns an English label for the given confidence value.
  static String confidenceLabelEn(double value) {
    if (value >= 0.95) return 'AI very confident';
    if (value >= 0.8) return 'AI fairly confident';
    if (value >= 0.5) return 'AI still learning';
    return 'AI uncertain';
  }
}
