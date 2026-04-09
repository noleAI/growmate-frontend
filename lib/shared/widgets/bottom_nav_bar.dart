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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: GrowMateColors.primary.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 64, 74, 0.11),
            blurRadius: 18,
            offset: Offset(0, -8),
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
                ? GrowMateColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? GrowMateColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? selectedColor : baseColor, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : baseColor,
                  fontSize: 12,
                  letterSpacing: 0.25,
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
