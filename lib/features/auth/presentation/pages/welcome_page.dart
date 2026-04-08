import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const SizedBox(height: 46),
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.tertiaryContainer,
                  boxShadow: const [
                    BoxShadow(
                      color: GrowMateColors.shadowSoft,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 56,
                  color: GrowMateColors.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chào bạn đến với GrowMate 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GrowMateColors.textPrimary,
                fontSize: 34,
                height: 1.24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cùng học tập nhẹ nhàng hơn mỗi ngày',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GrowMateColors.textSecondary,
                fontSize: 20,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 34),
            ZenCard(
              radius: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ZenButton(
                    label: 'Đăng nhập',
                    onPressed: () => context.push(AppRoutes.login),
                  ),
                  const SizedBox(height: 12),
                  ZenButton(
                    label: 'Tạo tài khoản',
                    variant: ZenButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                  const SizedBox(height: 10),
                  ZenButton(
                    label: 'Tiếp tục với Google',
                    variant: ZenButtonVariant.text,
                    leading: const Icon(
                      Icons.g_mobiledata_rounded,
                      color: GrowMateColors.primary,
                      size: 28,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng Google Sign-In sẽ sớm có trong bản tiếp theo ✨',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Mỗi phiên học chỉ cần một nhịp nhỏ, bạn đang làm rất tốt rồi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GrowMateColors.textSecondary,
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
