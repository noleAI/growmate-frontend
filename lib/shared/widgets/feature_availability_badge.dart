import 'package:flutter/material.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../models/feature_availability.dart';

class FeatureAvailabilityBadge extends StatelessWidget {
  const FeatureAvailabilityBadge({
    super.key,
    required this.availability,
    this.compact = false,
  });

  final FeatureAvailability availability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (availability) {
      FeatureAvailability.server => (
        colors.primaryContainer.withValues(alpha: 0.72),
        colors.primary,
        Icons.cloud_done_rounded,
      ),
      FeatureAvailability.localFallback => (
        colors.secondaryContainer.withValues(alpha: 0.72),
        colors.secondary,
        Icons.save_as_rounded,
      ),
      FeatureAvailability.beta => (
        colors.tertiaryContainer.withValues(alpha: 0.76),
        colors.tertiary,
        Icons.science_rounded,
      ),
      FeatureAvailability.requiresBackend => (
        colors.errorContainer.withValues(alpha: 0.82),
        colors.error,
        Icons.cloud_off_rounded,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: foreground),
          if ((_label(context)).trim().isNotEmpty) ...[
            SizedBox(width: compact ? 4 : 6),
            Text(
              _label(context),
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _label(BuildContext context) {
    return switch (availability) {
      // Hide the 'Máy chủ' label globally by returning an empty string.
      FeatureAvailability.server => '',
      FeatureAvailability.localFallback => context.t(
        vi: 'Dự phòng cục bộ',
        en: 'Local fallback',
      ),
      FeatureAvailability.beta => context.t(
        vi: 'Beta cục bộ',
        en: 'Local beta',
      ),
      FeatureAvailability.requiresBackend => context.t(
        vi: 'Cần backend',
        en: 'Requires backend',
      ),
    };
  }
}
