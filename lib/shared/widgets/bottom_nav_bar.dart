import 'package:flutter/material.dart';

import '../../app/i18n/app_strings.dart';

enum GrowMateTab { today, progress, roadmap, profile, settings }

class GrowMateBottomNavBar extends StatelessWidget {
  const GrowMateBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final GrowMateTab currentTab;
  final ValueChanged<GrowMateTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            label: strings.tabHome,
            icon: Icons.home_rounded,
            selected: currentTab == GrowMateTab.today,
            onTap: () => onTabSelected(GrowMateTab.today),
          ),
          _NavItem(
            label: strings.tabProgress,
            icon: Icons.bar_chart_rounded,
            selected: currentTab == GrowMateTab.progress,
            onTap: () => onTabSelected(GrowMateTab.progress),
          ),
          _NavItem(
            label: strings.tabRoadmap,
            icon: Icons.route_rounded,
            selected: currentTab == GrowMateTab.roadmap,
            onTap: () => onTabSelected(GrowMateTab.roadmap),
          ),
          _NavItem(
            label: strings.tabProfile,
            icon: Icons.person_rounded,
            selected: currentTab == GrowMateTab.profile,
            onTap: () => onTabSelected(GrowMateTab.profile),
          ),
          _NavItem(
            label: strings.tabSettings,
            icon: Icons.settings_rounded,
            selected: currentTab == GrowMateTab.settings,
            onTap: () => onTabSelected(GrowMateTab.settings),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedColor = colors.primary;
    final baseColor = colors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected ? selectedColor : baseColor,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? selectedColor : baseColor,
                    fontSize: 12,
                    letterSpacing: 0,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
