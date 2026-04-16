import 'package:flutter/material.dart';

import 'colors.dart';

/// Centralized typography tokens for the "Living Intelligence" design system.
///
/// Two voices:
/// - **AI Voice** — used when AI "speaks": insights, decisions, reasoning.
/// - **Human Voice** — standard user-facing content.
/// - **Data/Metrics** — JetBrains Mono for numbers and technical data.
class GrowMateTextStyles {
  GrowMateTextStyles._();

  // ── AI Voice ────────────────────────────────────────────────────────────────

  static final TextStyle aiHeadline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 28,
    color: GrowMateColors.aiCore(),
  );

  static const TextStyle aiBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GrowMateColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle aiMeta = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02 * 12,
    color: GrowMateColors.textSecondary,
  );

  /// All-caps block type label (overline).
  static final TextStyle blockLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: GrowMateColors.aiCore(),
  );

  // ── Human Voice ─────────────────────────────────────────────────────────────

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.03 * 32,
    color: GrowMateColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 24,
    color: GrowMateColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01 * 20,
    color: GrowMateColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GrowMateColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GrowMateColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01 * 12,
    color: GrowMateColors.textSecondary,
  );

  // ── Data / Metrics ───────────────────────────────────────────────────────────

  static final TextStyle metric = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 36,
    color: GrowMateColors.aiCore(),
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05 * 11,
    color: GrowMateColors.textSecondary,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: GrowMateColors.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.04 * 11,
    color: GrowMateColors.textSecondary,
  );

  // ── Overline ─────────────────────────────────────────────────────────────────

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08 * 11,
    color: GrowMateColors.textSecondary,
  );
}
