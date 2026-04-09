import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                  'Điều khoản sử dụng',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GrowMateColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TermSection(
              title: '1. Phạm vi dịch vụ',
              content:
                  'GrowMate cung cấp công cụ hỗ trợ học tập bằng AI và không thay thế hoàn toàn giáo viên hoặc chuyên gia tư vấn.',
            ),
            _TermSection(
              title: '2. Trách nhiệm người dùng',
              content:
                  'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và cung cấp dữ liệu trung thực để hệ thống đưa gợi ý phù hợp.',
            ),
            _TermSection(
              title: '3. Hành vi không được phép',
              content:
                  'Không được sử dụng ứng dụng vào mục đích vi phạm pháp luật, gây hại hoặc cố ý làm sai lệch hệ thống đánh giá.',
            ),
            _TermSection(
              title: '4. Giới hạn trách nhiệm',
              content:
                  'GrowMate nỗ lực đảm bảo độ chính xác cao nhưng không cam kết tuyệt đối cho mọi tình huống học tập.',
            ),
            _TermSection(
              title: '5. Cập nhật điều khoản',
              content:
                  'Điều khoản có thể được cập nhật để phù hợp với thay đổi sản phẩm hoặc pháp lý. Phiên bản mới sẽ được thông báo trong ứng dụng.',
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
