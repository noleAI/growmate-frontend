import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

enum GrowMateTab { today, progress, profile }

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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: GrowMateColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'HÔM NAY',
            icon: Icons.calendar_month_rounded,
            selected: currentTab == GrowMateTab.today,
            onTap: () => onTabSelected(GrowMateTab.today),
          ),
          _NavItem(
            label: 'TIẾN TRÌNH',
            icon: Icons.bar_chart_rounded,
            selected: currentTab == GrowMateTab.progress,
            onTap: () => onTabSelected(GrowMateTab.progress),
          ),
          _NavItem(
            label: 'HỒ SƠ',
            icon: Icons.person_rounded,
            selected: currentTab == GrowMateTab.profile,
            onTap: () => onTabSelected(GrowMateTab.profile),
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
    final selectedColor = GrowMateColors.primary;
    final baseColor = GrowMateColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? GrowMateColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? selectedColor : baseColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : baseColor,
                  fontSize: 14,
                  letterSpacing: 0.4,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}