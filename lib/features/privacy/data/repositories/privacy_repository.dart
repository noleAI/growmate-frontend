import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../achievement/data/repositories/achievement_repository.dart';
import '../../../notification/data/repositories/notification_repository.dart';
import '../../../offline/data/repositories/offline_mode_repository.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../../../schedule/data/repositories/study_schedule_repository.dart';
import '../../../session/data/repositories/session_history_repository.dart';

class PrivacyRepository {
  const PrivacyRepository({
    required this.profileRepository,
    required this.notificationRepository,
    required this.sessionHistoryRepository,
  });

  final ProfileRepository profileRepository;
  final NotificationRepository notificationRepository;
  final SessionHistoryRepository sessionHistoryRepository;

  Future<Map<String, dynamic>> buildPersonalDataExport({
    required String userId,
    required String email,
  }) async {
    UserProfile? profile;
    try {
      profile = await profileRepository.fetchProfile(userId);
    } catch (_) {
      profile = null;
    }

    final notifications = await notificationRepository.getNotifications();
    final sessionHistory = await sessionHistoryRepository.getHistory();
    final spacedReviews = await SpacedRepetitionRepository.instance.getItems();
    final achievements = await AchievementRepository.instance.getUnlocked();
    final scheduleItems = await StudyScheduleRepository.instance.getItems();
    final offlineState = await OfflineModeRepository.instance.getState();

    return <String, dynamic>{
      'schemaVersion': '1.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'account': <String, dynamic>{'userId': userId, 'email': email},
      'profile': profile?.toJson(),
      'sessionHistory': sessionHistory
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'notifications': notifications
          .map((notification) => notification.toJson())
          .toList(growable: false),
      'spacedReviews': spacedReviews
          .map((item) => item.toJson())
          .toList(growable: false),
      'achievements': achievements
          .map((item) => item.toJson())
          .toList(growable: false),
      'studySchedule': scheduleItems
          .map((item) => item.toJson())
          .toList(growable: false),
      'offlineState': <String, dynamic>{
        'enabled': offlineState.enabled,
        'queuedSignals': offlineState.queuedSignals,
        'lastSyncedAt': offlineState.lastSyncedAt?.toIso8601String(),
      },
    };
  }

  Future<void> clearLocalPersonalData({required String userId}) async {
    await notificationRepository.clearAll();
    await sessionHistoryRepository.clearHistory();
    await SpacedRepetitionRepository.instance.clearAll();
    await AchievementRepository.instance.clearAll();
    await StudyScheduleRepository.instance.clearAll();
    await OfflineModeRepository.instance.clearQueue();
    await profileRepository.clearCachedProfile(userId);
  }

  Future<void> deleteAccountData({required String userId}) async {
    await profileRepository.deleteProfile(userId);
    await clearLocalPersonalData(userId: userId);
  }
}
