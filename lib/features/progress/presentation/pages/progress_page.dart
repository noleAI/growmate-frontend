import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: const [
            GrowMateTopAppBar(),
            SizedBox(height: 28),
            ZenCard(
              radius: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến trình nhẹ nhàng',
                    style: TextStyle(
                      color: GrowMateColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.22,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Bạn đang duy trì nhịp học rất ổn. Mình sẽ cập nhật biểu đồ chi tiết sau khi có thêm dữ liệu phiên học nhé.',
                    style: TextStyle(
                      color: GrowMateColors.textSecondary,
                      fontSize: 20,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.progress,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}