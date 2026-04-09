import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/app_routes.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  static const String _notificationsKey = 'notifications_v1';
  static const String _reminderSettingsKey = 'study_reminder_settings_v1';
  static const String _lastReminderDayKey = 'study_reminder_last_day_v1';

  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  bool _bootstrapped = false;

  Stream<List<AppNotification>> watchNotifications() async* {
    final snapshot = await getNotifications();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    _bootstrapped = true;
    await ensureDailyStudyReminderIfNeeded();
    await ensureSpacedReviewReminderIfNeeded();
  }

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);

    if (raw == null || raw.isEmpty) {
      return <AppNotification>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <AppNotification>[];
      }

      final notifications =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    AppNotification.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (_) {
      await prefs.remove(_notificationsKey);
      return <AppNotification>[];
    }
  }

  Future<int> getUnreadCount() async {
    final items = await getNotifications();
    return items.where((item) => !item.isRead).length;
  }

  Future<void> addNotification({
    required String category,
    required String title,
    required String message,
    required String targetRoute,
    Map<String, String> targetQuery = const <String, String>{},
    String? dedupeKey,
  }) async {
    final current = await getNotifications();

    if (dedupeKey != null && dedupeKey.trim().isNotEmpty) {
      final duplicated = current.any((item) => item.dedupeKey == dedupeKey);
      if (duplicated) {
        return;
      }
    }

    final created = AppNotification(
      id: 'n_${DateTime.now().microsecondsSinceEpoch}',
      category: category,
      title: title,
      message: message,
      targetRoute: targetRoute,
      targetQuery: targetQuery,
      createdAt: DateTime.now().toUtc(),
      isRead: false,
      dedupeKey: dedupeKey,
    );

    final next = <AppNotification>[created, ...current]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _persist(next);
  }

  Future<void> markAsRead(String id) async {
    final current = await getNotifications();
    final next = current
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> markAllAsRead() async {
    final current = await getNotifications();
    if (current.isEmpty) {
      return;
    }

    final next = current
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);

    await _persist(next);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    _controller.add(<AppNotification>[]);
  }

  Future<StudyReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reminderSettingsKey);

    if (raw == null || raw.isEmpty) {
      return const StudyReminderSettings(enabled: true, hour: 20, minute: 30);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const StudyReminderSettings(enabled: true, hour: 20, minute: 30);
      }

      return StudyReminderSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const StudyReminderSettings(enabled: true, hour: 20, minute: 30);
    }
  }

  Future<void> updateReminderSettings(StudyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderSettingsKey, jsonEncode(settings.toJson()));

    if (settings.enabled) {
      await ensureDailyStudyReminderIfNeeded();
    }
  }

  Future<void> ensureDailyStudyReminderIfNeeded({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final settings = await getReminderSettings();

    if (!settings.enabled) {
      return;
    }

    final scheduledTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      settings.hour,
      settings.minute,
    );

    if (currentTime.isBefore(scheduledTime)) {
      return;
    }

    final dayKey =
        '${currentTime.year.toString().padLeft(4, '0')}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    final lastReminderDay = prefs.getString(_lastReminderDayKey);
    if (lastReminderDay == dayKey) {
      return;
    }

    await addNotification(
      category: 'study_reminder',
      title: 'Nhắc học theo lịch hôm nay',
      message:
          'Đến giờ ôn tập rồi nè. Dành 10-15 phút để giữ nhịp học đều nhé.',
      targetRoute: AppRoutes.quiz,
      dedupeKey: 'study-reminder-$dayKey',
    );

    await prefs.setString(_lastReminderDayKey, dayKey);
  }

  Future<void> pushInterventionEvent({
    required String submissionId,
    required String diagnosisId,
    required String mode,
  }) {
    return addNotification(
      category: 'intervention',
      title: 'Can thiệp học tập mới',
      message: mode == 'recovery'
          ? 'AI đề xuất Recovery Mode để bạn lấy lại năng lượng.'
          : 'AI đề xuất một can thiệp ngắn để giữ nhịp học.',
      targetRoute: AppRoutes.intervention,
      targetQuery: <String, String>{
        'submissionId': submissionId,
        'diagnosisId': diagnosisId,
        'mode': mode,
        'source': 'notification',
      },
      dedupeKey: 'intervention-start-$submissionId-$diagnosisId',
    );
  }

  Future<void> pushSessionCompletedEvent({
    required String topic,
    required String nextAction,
    required String sourceKey,
  }) {
    return addNotification(
      category: 'session',
      title: 'Tiến trình vừa được cập nhật',
      message: 'Phiên "$topic" đã lưu xong. Gợi ý ngày mai: $nextAction',
      targetRoute: AppRoutes.progress,
      targetQuery: const <String, String>{'focus': 'weekly-plan'},
      dedupeKey: 'session-complete-$sourceKey',
    );
  }

  Future<void> pushMindfulBreakEvent({
    required String sourceKey,
    String? reason,
  }) {
    final normalizedReason = reason?.trim();

    return addNotification(
      category: 'wellness',
      title: 'Đã đến lúc nghỉ 90 giây',
      message: normalizedReason == null || normalizedReason.isEmpty
          ? 'Mình đề xuất một mindful break ngắn để bạn hồi phục nhịp tập trung.'
          : 'Mình phát hiện dấu hiệu $normalizedReason, bạn nghỉ 90 giây nhé.',
      targetRoute: AppRoutes.mindfulBreak,
      dedupeKey: 'mindful-break-$sourceKey',
    );
  }

  Future<void> pushBadgeUnlockedEvent({
    required String badgeId,
    required String badgeTitle,
  }) {
    return addNotification(
      category: 'achievement',
      title: 'Bạn vừa mở huy hiệu mới',
      message: 'Huy hiệu "$badgeTitle" đã được mở khóa.',
      targetRoute: AppRoutes.progress,
      targetQuery: const <String, String>{'focus': 'badges'},
      dedupeKey: 'badge-unlocked-$badgeId',
    );
  }

  Future<void> ensureSpacedReviewReminderIfNeeded({DateTime? now}) async {
    final dueItems = await SpacedRepetitionRepository.instance.getDueItems(
      now: now,
    );

    if (dueItems.isEmpty) {
      return;
    }

    final reference = (now ?? DateTime.now());
    final dayKey =
        '${reference.year.toString().padLeft(4, '0')}-${reference.month.toString().padLeft(2, '0')}-${reference.day.toString().padLeft(2, '0')}';

    await addNotification(
      category: 'review',
      title: 'Lịch ôn tập hôm nay đã sẵn sàng',
      message:
          'Bạn có ${dueItems.length} chủ đề đến lịch ôn theo spaced repetition.',
      targetRoute: AppRoutes.progress,
      targetQuery: const <String, String>{'focus': 'spaced-review'},
      dedupeKey: 'spaced-review-$dayKey',
    );
  }

  Future<void> _persist(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      notifications.map((item) => item.toJson()).toList(growable: false),
    );
    await prefs.setString(_notificationsKey, raw);
    _controller.add(notifications);
  }
}
