import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class SessionCompletePage extends StatelessWidget {
  const SessionCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const GrowMateTopAppBar(),
            const SizedBox(height: 14),
            SizedBox(
              height: 292,
              child: ZenCard(
                radius: 36,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFF7ED), Color(0xFFE5F0EA)],
                ),
                child: Center(
                  child: Container(
                    width: 142,
                    height: 142,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD7E9CF), Color(0xFFC1DDC1)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: GrowMateColors.shadowSoft,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.energy_savings_leaf_rounded,
                      size: 78,
                      color: GrowMateColors.success,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hôm nay bạn học\nrất ổn ✨',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: GrowMateColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: GrowMateColors.tertiaryContainer,
                  border: Border.all(
                    color: GrowMateColors.success.withValues(alpha: 0.16),
                  ),
                ),
                child: const Text(
                  '✧ HÀNH TRÌNH TUYỆT VỜI',
                  style: TextStyle(
                    color: GrowMateColors.success,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ZenCard(
              radius: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoundedInfoIcon(
                    icon: Icons.psychology_alt_rounded,
                    color: GrowMateColors.tertiaryContainer,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bạn đã hiểu rõ hơn về\nĐạo hàm rồi đó!',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: GrowMateColors.textPrimary,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ghi nhớ: Quy tắc đạo hàm hàm hợp',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: GrowMateColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ZenCard(
              radius: 30,
              color: const Color(0xFFEAF0EE),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoundedInfoIcon(
                    icon: Icons.favorite_rounded,
                    color: Color(0xFFD4E2DF),
                    iconColor: GrowMateColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '"Cảm ơn bạn đã đồng hành cùng mình hôm nay nha!"',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: GrowMateColors.textSecondary,
                        height: 1.48,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ZenButton(
              label: 'Kết thúc phiên học',
              onPressed: () => context.go(AppRoutes.home),
            ),
            const SizedBox(height: 14),
            ZenButton(
              label: 'Xem lại ghi chú',
              variant: ZenButtonVariant.secondary,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng ghi chú sẽ có trong bản mở rộng.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.today,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _RoundedInfoIcon extends StatelessWidget {
  const _RoundedInfoIcon({
    required this.icon,
    required this.color,
    this.iconColor = GrowMateColors.success,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
