import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
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
                  context.t(
                    vi: 'Chính sách quyền riêng tư',
                    en: 'Privacy policy',
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GrowMateColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PolicySection(
              title: context.t(
                vi: '1. Dữ liệu được thu thập',
                en: '1. Data collected',
              ),
              content: context.t(
                vi: 'GrowMate lưu thông tin hồ sơ học tập, tín hiệu tương tác trong phiên và lịch sử phiên học để cá nhân hóa lộ trình. Bạn có thể tắt các cờ consent trong phần Cài đặt.',
                en: 'GrowMate stores learning profile information, in-session interaction signals, and session history to personalize your roadmap. You can disable consent flags in Settings.',
              ),
            ),
            _PolicySection(
              title: context.t(
                vi: '2. Mục đích sử dụng',
                en: '2. Purpose of use',
              ),
              content: context.t(
                vi: 'Dữ liệu được dùng để đưa ra gợi ý học phù hợp, cảnh báo khi bạn có dấu hiệu quá tải và cải thiện chất lượng phản hồi AI theo thời gian.',
                en: 'Data is used to generate relevant study guidance, warn when overload signals appear, and improve AI response quality over time.',
              ),
            ),
            _PolicySection(
              title: context.t(vi: '3. Quyền của bạn', en: '3. Your rights'),
              content: context.t(
                vi: 'Bạn có quyền xuất dữ liệu cá nhân, chỉnh sửa hồ sơ, tắt thu thập analytics, và yêu cầu xóa tài khoản ngay trong ứng dụng.',
                en: 'You can export personal data, edit your profile, disable analytics collection, and request account deletion directly in the app.',
              ),
            ),
            _PolicySection(
              title: context.t(
                vi: '4. Lưu trữ và bảo mật',
                en: '4. Storage and security',
              ),
              content: context.t(
                vi: 'Dữ liệu được lưu cục bộ có mã hóa và/hoặc trên backend có kiểm soát quyền truy cập. GrowMate không bán dữ liệu cá nhân cho bên thứ ba.',
                en: 'Data is stored locally with encryption and/or on backend services with access control. GrowMate does not sell personal data to third parties.',
              ),
            ),
            _PolicySection(
              title: context.t(vi: '5. Liên hệ', en: '5. Contact'),
              content: context.t(
                vi: 'Nếu cần hỗ trợ về quyền riêng tư, vui lòng gửi email đến privacy@growmate.vn.',
                en: 'If you need privacy support, please email privacy@growmate.vn.',
              ),
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
