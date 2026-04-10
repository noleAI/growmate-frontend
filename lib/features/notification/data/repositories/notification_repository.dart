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
  static const String _appLanguageKey = 'app_language';

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

    final isEnglish = _isEnglishLanguage(prefs);

    await addNotification(
      category: 'study_reminder',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Nhắc học theo lịch hôm nay',
        en: 'Today\'s study reminder',
      ),
      message: _pick(
        isEnglish: isEnglish,
        vi: 'Đến giờ ôn tập rồi nè. Dành 10-15 phút để giữ nhịp học đều nhé.',
        en: 'It is review time. Spend 10-15 minutes to maintain your study rhythm.',
      ),
      targetRoute: AppRoutes.quiz,
      dedupeKey: 'study-reminder-$dayKey',
    );

    await prefs.setString(_lastReminderDayKey, dayKey);
  }

  Future<void> pushInterventionEvent({
    required String submissionId,
    required String diagnosisId,
    required String mode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = _isEnglishLanguage(prefs);

    await addNotification(
      category: 'intervention',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Can thiệp học tập mới',
        en: 'New study intervention',
      ),
      message: mode == 'recovery'
          ? _pick(
              isEnglish: isEnglish,
              vi: 'AI đề xuất chế độ phục hồi để bạn lấy lại năng lượng.',
              en: 'AI suggests Recovery Mode to help you regain energy.',
            )
          : _pick(
              isEnglish: isEnglish,
              vi: 'AI đề xuất một can thiệp ngắn để giữ nhịp học.',
              en: 'AI suggests a short intervention to keep your learning rhythm steady.',
            ),
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = _isEnglishLanguage(prefs);
    final trimmedNextAction = nextAction.trim();
    final safeNextActionEn = trimmedNextAction.isEmpty
        ? null
        : (_containsVietnameseChars(trimmedNextAction)
              ? null
              : trimmedNextAction);

    await addNotification(
      category: 'session',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Tiến trình vừa được cập nhật',
        en: 'Progress updated',
      ),
      message: _pick(
        isEnglish: isEnglish,
        vi: 'Phiên "$topic" đã lưu xong. Mở Tiến trình để xem gợi ý cho ngày mai.',
        en: safeNextActionEn == null
            ? 'Your latest session was saved. Check Progress for the next suggested action.'
            : 'Your latest session was saved. Suggested next action: $safeNextActionEn',
      ),
      targetRoute: AppRoutes.progress,
      targetQuery: const <String, String>{'focus': 'weekly-plan'},
      dedupeKey: 'session-complete-$sourceKey',
    );
  }

  Future<void> pushMindfulBreakEvent({
    required String sourceKey,
    String? reason,
  }) async {
    final normalizedReason = reason?.trim();
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = _isEnglishLanguage(prefs);
    final safeReasonEn = (normalizedReason == null || normalizedReason.isEmpty)
        ? null
        : (_containsVietnameseChars(normalizedReason)
              ? null
              : normalizedReason);
    final safeReasonVi = (normalizedReason == null || normalizedReason.isEmpty)
        ? null
        : (_containsVietnameseChars(normalizedReason)
              ? normalizedReason
              : null);

    await addNotification(
      category: 'wellness',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Đã đến lúc nghỉ 90 giây',
        en: 'Time for a 90-second break',
      ),
      message: normalizedReason == null || normalizedReason.isEmpty
          ? _pick(
              isEnglish: isEnglish,
              vi: 'Mình đề xuất một khoảng nghỉ thở ngắn để bạn hồi phục nhịp tập trung.',
              en: 'Take a short mindful break to restore your focus rhythm.',
            )
          : _pick(
              isEnglish: isEnglish,
              vi: safeReasonVi == null
                  ? 'Mình phát hiện dấu hiệu quá tải, bạn nghỉ 90 giây nhé.'
                  : 'Mình phát hiện dấu hiệu $safeReasonVi, bạn nghỉ 90 giây nhé.',
              en: safeReasonEn == null
                  ? 'Detected overload signals. Take a 90-second break.'
                  : 'Detected signal "$safeReasonEn". Take a 90-second break.',
            ),
      targetRoute: AppRoutes.mindfulBreak,
      dedupeKey: 'mindful-break-$sourceKey',
    );
  }

  Future<void> pushBadgeUnlockedEvent({
    required String badgeId,
    required String badgeTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = _isEnglishLanguage(prefs);

    await addNotification(
      category: 'achievement',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Bạn vừa mở huy hiệu mới',
        en: 'New badge unlocked',
      ),
      message: _pick(
        isEnglish: isEnglish,
        vi: 'Huy hiệu "$badgeTitle" đã được mở khóa.',
        en: 'A new badge has been unlocked.',
      ),
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
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = _isEnglishLanguage(prefs);

    await addNotification(
      category: 'review',
      title: _pick(
        isEnglish: isEnglish,
        vi: 'Lịch ôn tập hôm nay đã sẵn sàng',
        en: 'Today\'s review plan is ready',
      ),
      message: _pick(
        isEnglish: isEnglish,
        vi: 'Bạn có ${dueItems.length} chủ đề đến lịch ôn tập ngắt quãng.',
        en: '${dueItems.length} topic(s) are due for spaced-repetition review.',
      ),
      targetRoute: AppRoutes.progress,
      targetQuery: const <String, String>{'focus': 'spaced-review'},
      dedupeKey: 'spaced-review-$dayKey',
    );
  }

  static bool _isEnglishLanguage(SharedPreferences prefs) {
    final language = prefs.getString(_appLanguageKey) ?? 'vi';
    return language.toLowerCase().startsWith('en');
  }

  static String _pick({
    required bool isEnglish,
    required String vi,
    required String en,
  }) {
    return isEnglish ? en : vi;
  }

  static bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
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
