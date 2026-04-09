import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GrowMateColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Thông báo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Nhắc học theo lịch và sự kiện can thiệp sẽ xuất hiện tại đây.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _buildReminderCard(theme),
            const SizedBox(height: 14),
            StreamBuilder<List<AppNotification>>(
              stream: widget.notificationRepository.watchNotifications(),
              builder: (context, snapshot) {
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
                          'Hộp thư của bạn',
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
                            child: Text('Đánh dấu đã đọc ($unreadCount)'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (notifications.isEmpty)
                      ZenCard(
                        radius: 18,
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Text(
                          'Chưa có thông báo mới. GrowMate sẽ nhắc khi tới lịch học hoặc khi có can thiệp quan trọng.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: GrowMateColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...notifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openNotification(item),
                            child: ZenCard(
                              radius: 18,
                              color: item.isRead
                                  ? theme.colorScheme.surfaceContainerLow
                                  : GrowMateColors.primaryContainer.withValues(
                                      alpha: 0.4,
                                    ),
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
                                                item.title,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: GrowMateColors
                                                          .textPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            if (!item.isRead)
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
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: GrowMateColors
                                                    .textSecondary,
                                                height: 1.4,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _timeAgoLabel(item.createdAt),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: GrowMateColors
                                                    .textSecondary,
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
              const Icon(
                Icons.alarm_rounded,
                color: GrowMateColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nhắc học theo lịch',
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
            'Khi tới giờ, GrowMate sẽ tạo nhắc học và deep-link vào phiên luyện tập.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: GrowMateColors.textSecondary,
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
                child: const Text('Đổi giờ nhắc'),
              ),
            ],
          ),
        ],
      ),
    );
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

  static String _timeAgoLabel(DateTime createdAtUtc) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAtUtc);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    return '${diff.inDays} ngày trước';
  }
}
