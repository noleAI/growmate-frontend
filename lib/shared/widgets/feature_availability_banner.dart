import 'package:flutter/material.dart';

import 'feature_availability_badge.dart';
import '../models/feature_availability.dart';

class FeatureAvailabilityBanner extends StatelessWidget {
  const FeatureAvailabilityBanner({
    super.key,
    required this.availability,
    required this.message,
  });

  final FeatureAvailability availability;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Color background = switch (availability) {
      FeatureAvailability.server => colors.primaryContainer.withValues(
        alpha: 0.34,
      ),
      FeatureAvailability.localFallback => colors.secondaryContainer.withValues(
        alpha: 0.4,
      ),
      FeatureAvailability.beta => colors.tertiaryContainer.withValues(
        alpha: 0.42,
      ),
      FeatureAvailability.requiresBackend => colors.errorContainer.withValues(
        alpha: 0.46,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeatureAvailabilityBadge(availability: availability, compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
