import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/models/feature_availability.dart';
import '../../../../shared/widgets/feature_availability_banner.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.notificationRepository});

  final NotificationRepository notificationRepository;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  StudyReminderSettings? _settings;
  bool _settingsLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.notificationRepository.bootstrap();
    await _reloadReminderSettings();
  }

  Future<void> _reloadReminderSettings() async {
    final settings = await widget.notificationRepository.getReminderSettings();
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _settingsLoading = false;
    });
  }

  Future<void> _toggleReminder(bool enabled) async {
    final settings =
        _settings ??
        const StudyReminderSettings(enabled: true, hour: 20, minute: 30);

    await widget.notificationRepository.updateReminderSettings(
      settings.copyWith(enabled: enabled),
    );
    await _reloadReminderSettings();
  }

  Future<void> _pickReminderTime() async {
    final settings =
        _settings ??
        const StudyReminderSettings(enabled: true, hour: 20, minute: 30);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );

    if (picked == null) {
      return;
    }

    await widget.notificationRepository.updateReminderSettings(
      settings.copyWith(hour: picked.hour, minute: picked.minute),
    );

    await _reloadReminderSettings();
  }

  Future<void> _openNotification(AppNotification item) async {
    await widget.notificationRepository.markAsRead(item.id);

    if (!mounted) {
      return;
    }

    final location = item.toLocation();
    if (location.trim().isEmpty) {
      return;
    }

    try {
      context.go(location);
    } on GoException {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  tooltip: context.t(vi: 'Quay lại', en: 'Back'),
                  padding: EdgeInsets.all(12),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  context.t(vi: 'Thông báo', en: 'Notifications'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.t(
                vi: 'Nhắc học theo lịch và sự kiện can thiệp sẽ xuất hiện tại đây.',
                en: 'Study reminders and intervention events will appear here.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GrowMateLayout.space12),
            FeatureAvailabilityBanner(
              availability: FeatureAvailability.beta,
              message: context.t(
                vi: 'Notifications hiện đang được quản lý local. Không nên xem đây là backend proof trong bản demo.',
                en: 'Notifications are currently managed locally. Do not treat this screen as backend proof in the demo.',
              ),
            ),
            const SizedBox(height: GrowMateLayout.space12),
            _buildReminderCard(theme),
            const SizedBox(height: GrowMateLayout.space12),
            StreamBuilder<List<AppNotification>>(
              stream: widget.notificationRepository.watchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorStateWidget(
                    message: context.t(
                      vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
                      en: 'Unable to load data. Please try again.',
                    ),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                if (!snapshot.hasData) {
                  return const _LoadingStateWidget();
                }

                final notifications =
                    snapshot.data ?? const <AppNotification>[];
                final unreadCount = notifications
                    .where((item) => !item.isRead)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.t(vi: 'Hộp thư của bạn', en: 'Your inbox'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: () {
                              widget.notificationRepository.markAllAsRead();
                            },
                            child: Text(
                              context.t(
                                vi: 'Đánh dấu đã đọc ($unreadCount)',
                                en: 'Mark all as read ($unreadCount)',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (notifications.isEmpty)
                      ZenCard(
                        radius: 18,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Text(
                          context.t(
                            vi: 'Chưa có thông báo mới. GrowMate sẽ nhắc khi tới lịch học hoặc khi có can thiệp quan trọng.',
                            en: 'No new notifications. GrowMate will remind you when it is study time or when an important intervention is needed.',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...notifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              GrowMateLayout.cardRadius,
                            ),
                            onTap: () => _openNotification(item),
                            child: ZenCard(
                              radius: GrowMateLayout.cardRadius,
                              color: item.isRead
                                  ? theme.colorScheme.surfaceContainerLow
                                  : theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _iconForCategory(item.category),
                                      color: theme.colorScheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _notificationTitle(
                                                  context,
                                                  item,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _notificationMessage(context, item),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _timeAgoLabel(
                                            context,
                                            item.createdAt,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(ThemeData theme) {
    final settings = _settings;
    final loading = _settingsLoading || settings == null;

    return ZenCard(
      radius: 18,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.t(vi: 'Nhắc học theo lịch', en: 'Scheduled reminder'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: settings?.enabled ?? false,
                onChanged: loading ? null : _toggleReminder,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              vi: 'Khi tới giờ, GrowMate sẽ tạo nhắc học và deep-link vào phiên luyện tập.',
              en: 'At the set time, GrowMate creates a reminder and deep-links to your study session.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  settings == null
                      ? '--:--'
                      : '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: loading ? null : _pickReminderTime,
                child: Text(
                  context.t(vi: 'Đổi giờ nhắc', en: 'Change reminder time'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _notificationTitle(BuildContext context, AppNotification item) {
    if (!context.isEnglish) {
      return item.title;
    }

    switch (item.category) {
      case 'study_reminder':
        return 'Today\'s study reminder';
      case 'intervention':
        return 'New study intervention';
      case 'session':
        return 'Progress updated';
      case 'wellness':
        return '90-second mindful break';
      case 'achievement':
        return 'New badge unlocked';
      case 'review':
        return 'Today\'s review plan is ready';
      default:
        return _containsVietnameseChars(item.title)
            ? 'New notification'
            : item.title;
    }
  }

  String _notificationMessage(BuildContext context, AppNotification item) {
    if (!context.isEnglish) {
      return item.message;
    }

    switch (item.category) {
      case 'study_reminder':
        return 'It is review time. Spend 10-15 minutes to maintain your study rhythm.';
      case 'intervention':
        return item.targetQuery['mode'] == 'recovery'
            ? 'AI suggests Recovery Mode to help you regain energy.'
            : 'AI suggests a short intervention to keep your learning rhythm steady.';
      case 'session':
        return 'Your recent session was saved. Check Progress for the next suggested action.';
      case 'wellness':
        return 'Take a short mindful break to recover focus and continue gently.';
      case 'achievement':
        return 'A new achievement badge has been unlocked.';
      case 'review':
        final countMatch = RegExp(r'(\d+)').firstMatch(item.message);
        final count = countMatch?.group(1);
        if (count == null) {
          return 'Topics are due for spaced-repetition review.';
        }
        return '$count topic(s) are due for spaced-repetition review.';
      default:
        return _containsVietnameseChars(item.message)
            ? 'Open this notification for more details.'
            : item.message;
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'study_reminder':
        return Icons.alarm_rounded;
      case 'review':
        return Icons.refresh_rounded;
      case 'intervention':
        return Icons.health_and_safety_rounded;
      case 'session':
        return Icons.timeline_rounded;
      case 'wellness':
        return Icons.spa_rounded;
      case 'achievement':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  String _timeAgoLabel(BuildContext context, DateTime createdAtUtc) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAtUtc);

    if (diff.inSeconds < 60) {
      return context.t(vi: 'Vừa xong', en: 'Just now');
    }
    if (diff.inMinutes < 60) {
      return context.t(
        vi: '${diff.inMinutes} phút trước',
        en: '${diff.inMinutes} min ago',
      );
    }
    if (diff.inHours < 24) {
      return context.t(
        vi: '${diff.inHours} giờ trước',
        en: '${diff.inHours} hr ago',
      );
    }
    return context.t(
      vi: '${diff.inDays} ngày trước',
      en: '${diff.inDays} day(s) ago',
    );
  }

  bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
  }
}

class _ErrorStateWidget extends StatelessWidget {
  const _ErrorStateWidget({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 18,
      color: colors.errorContainer.withValues(alpha: 0.15),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 32, color: colors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: 18, color: colors.error),
            label: Text(
              context.t(vi: 'Thử lại', en: 'Retry'),
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 18,
      color: colors.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Text(
            context.t(vi: 'Đang tải dữ liệu...', en: 'Loading data...'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
