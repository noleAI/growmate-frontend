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
    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const GrowMateTopAppBar(),
            const SizedBox(height: 20),
            Container(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(46),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0E2133), Color(0xFF102E39)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 148,
                  color: Color(0xFF9BD973),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hôm nay bạn học\nrất ổn ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GrowMateColors.textPrimary,
                fontSize: 62 / 2,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: GrowMateColors.tertiaryContainer,
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
            const ZenCard(
              radius: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundedInfoIcon(
                    icon: Icons.psychology_alt_rounded,
                    color: GrowMateColors.tertiaryContainer,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bạn đã hiểu rõ hơn về\nĐạo hàm rồi đó!',
                          style: TextStyle(
                            color: GrowMateColors.textPrimary,
                            fontSize: 20,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ghi nhớ: Quy tắc đạo hàm hàm hợp',
                          style: TextStyle(
                            color: GrowMateColors.textSecondary,
                            fontSize: 17,
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
            const ZenCard(
              radius: 30,
              color: Color(0xFFEFEFF7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundedInfoIcon(
                    icon: Icons.favorite_rounded,
                    color: Color(0xFFD8DDFF),
                    iconColor: GrowMateColors.primary,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '"Cảm ơn bạn đã đồng hành cùng mình hôm nay nha!"',
                      style: TextStyle(
                        color: GrowMateColors.textSecondary,
                        fontSize: 22 / 1.2,
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
