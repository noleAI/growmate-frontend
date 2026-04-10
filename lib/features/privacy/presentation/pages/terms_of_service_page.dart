import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                  context.t(vi: 'Điều khoản sử dụng', en: 'Terms of service'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GrowMateColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TermSection(
              title: context.t(
                vi: '1. Phạm vi dịch vụ',
                en: '1. Service scope',
              ),
              content: context.t(
                vi: 'GrowMate cung cấp công cụ hỗ trợ học tập bằng AI và không thay thế hoàn toàn giáo viên hoặc chuyên gia tư vấn.',
                en: 'GrowMate provides AI-assisted learning tools and does not fully replace teachers or professional advisors.',
              ),
            ),
            _TermSection(
              title: context.t(
                vi: '2. Trách nhiệm người dùng',
                en: '2. User responsibilities',
              ),
              content: context.t(
                vi: 'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và cung cấp dữ liệu trung thực để hệ thống đưa gợi ý phù hợp.',
                en: 'You are responsible for securing login credentials and providing truthful data so the system can deliver relevant guidance.',
              ),
            ),
            _TermSection(
              title: context.t(
                vi: '3. Hành vi không được phép',
                en: '3. Prohibited behavior',
              ),
              content: context.t(
                vi: 'Không được sử dụng ứng dụng vào mục đích vi phạm pháp luật, gây hại hoặc cố ý làm sai lệch hệ thống đánh giá.',
                en: 'Do not use the app for unlawful purposes, harmful actions, or intentionally manipulating the evaluation system.',
              ),
            ),
            _TermSection(
              title: context.t(
                vi: '4. Giới hạn trách nhiệm',
                en: '4. Limitation of liability',
              ),
              content: context.t(
                vi: 'GrowMate nỗ lực đảm bảo độ chính xác cao nhưng không cam kết tuyệt đối cho mọi tình huống học tập.',
                en: 'GrowMate strives for high accuracy but does not guarantee absolute correctness for every learning scenario.',
              ),
            ),
            _TermSection(
              title: context.t(
                vi: '5. Cập nhật điều khoản',
                en: '5. Terms updates',
              ),
              content: context.t(
                vi: 'Điều khoản có thể được cập nhật để phù hợp với thay đổi sản phẩm hoặc pháp lý. Phiên bản mới sẽ được thông báo trong ứng dụng.',
                en: 'These terms may be updated to reflect product or legal changes. New versions will be announced in the app.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({required this.title, required this.content});

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
