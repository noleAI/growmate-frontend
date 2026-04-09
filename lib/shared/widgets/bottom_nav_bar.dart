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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 26,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'Hôm nay',
            icon: Icons.home_rounded,
            selected: currentTab == GrowMateTab.today,
            onTap: () => onTabSelected(GrowMateTab.today),
          ),
          _NavItem(
            label: 'Tiến trình',
            icon: Icons.bar_chart_rounded,
            selected: currentTab == GrowMateTab.progress,
            onTap: () => onTabSelected(GrowMateTab.progress),
          ),
          _NavItem(
            label: 'Hồ sơ',
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 30,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? GrowMateColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? selectedColor : baseColor,
                  size: 18,
                ),
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
    );
  }
}
