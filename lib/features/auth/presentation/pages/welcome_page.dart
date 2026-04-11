import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const SizedBox(height: 14),
            ZenCard(
              radius: 30,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF9FBF8), Color(0xFFF2EFE8)],
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEAF2E0), Color(0xFFD8E6D0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.energy_savings_leaf_rounded,
                      size: 48,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chào bạn đến với GrowMate',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 34,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Học nhẹ hơn, đều hơn, và vẫn hiệu quả từng ngày.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ZenCard(
              radius: 32,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
                    leading: Icon(
                      Icons.g_mobiledata_rounded,
                      color: theme.colorScheme.primary,
                      size: 30,
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
            const SizedBox(height: 18),
            Text(
              'Mỗi phiên học chỉ cần một nhịp nhỏ, bạn đang làm rất tốt rồi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
