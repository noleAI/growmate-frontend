import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go(AppRoutes.settings);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GrowMateColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Chính sách quyền riêng tư',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GrowMateColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PolicySection(
              title: '1. Dữ liệu được thu thập',
              content:
                  'GrowMate lưu thông tin hồ sơ học tập, tín hiệu tương tác trong phiên và lịch sử phiên học để cá nhân hóa lộ trình. Bạn có thể tắt các cờ consent trong phần Cài đặt.',
            ),
            _PolicySection(
              title: '2. Mục đích sử dụng',
              content:
                  'Dữ liệu được dùng để đưa ra gợi ý học phù hợp, cảnh báo khi bạn có dấu hiệu quá tải và cải thiện chất lượng phản hồi AI theo thời gian.',
            ),
            _PolicySection(
              title: '3. Quyền của bạn',
              content:
                  'Bạn có quyền xuất dữ liệu cá nhân, chỉnh sửa hồ sơ, tắt thu thập analytics, và yêu cầu xóa tài khoản ngay trong ứng dụng.',
            ),
            _PolicySection(
              title: '4. Lưu trữ và bảo mật',
              content:
                  'Dữ liệu được lưu cục bộ có mã hóa và/hoặc trên backend có kiểm soát quyền truy cập. GrowMate không bán dữ liệu cá nhân cho bên thứ ba.',
            ),
            _PolicySection(
              title: '5. Liên hệ',
              content:
                  'Nếu cần hỗ trợ về quyền riêng tư, vui lòng gửi email đến privacy@growmate.vn.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
