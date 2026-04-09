import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const notifications = <_NotificationItem>[
      _NotificationItem(
        title: 'Nhắc ôn tập nhẹ',
        message: 'Bạn có thể dành 10 phút ôn lại Đạo hàm hàm hợp hôm nay.',
        timeLabel: '5 phút trước',
        unread: true,
      ),
      _NotificationItem(
        title: 'Tiến trình đã cập nhật',
        message: 'Biểu đồ sức khỏe tinh thần vừa ghi nhận phiên học mới.',
        timeLabel: '1 giờ trước',
      ),
      _NotificationItem(
        title: 'Mẹo học nhanh',
        message: 'Khi bí, thử viết lại quy tắc đạo hàm theo từng bước nhỏ.',
        timeLabel: 'Hôm qua',
      ),
    ];

    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }

                    context.go(AppRoutes.home);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GrowMateColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Notification',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Các cập nhật dành riêng cho phiên học của bạn.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ...notifications.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZenCard(
                  radius: 18,
                  color: item.unread
                      ? GrowMateColors.primaryContainer.withValues(alpha: 0.34)
                      : Colors.white.withValues(alpha: 0.82),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: GrowMateColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (item.unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: GrowMateColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: GrowMateColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: GrowMateColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    this.unread = false,
  });

  final String title;
  final String message;
  final String timeLabel;
  final bool unread;
}
