import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Period tab bar: Tuần / Tháng / Tổng.
class PeriodTabBar extends StatelessWidget {
  const PeriodTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = [
      (
        'weekly',
        context.t(vi: 'Tuần', en: 'Week'),
        Icons.calendar_view_week_rounded,
      ),
      (
        'monthly',
        context.t(vi: 'Tháng', en: 'Month'),
        Icons.calendar_month_rounded,
      ),
      (
        'all_time',
        context.t(vi: 'Tổng', en: 'All Time'),
        Icons.all_inclusive_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selected == tab.$1;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelected(tab.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.$3,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.$2,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
