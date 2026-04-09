import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../session/data/models/session_history_entry.dart';
import '../models/achievement_badge.dart';

class AchievementRepository {
  AchievementRepository._();

  static final AchievementRepository instance = AchievementRepository._();

  static const String _storageKey = 'achievement_badges_v1';

  final StreamController<List<AchievementBadge>> _controller =
      StreamController<List<AchievementBadge>>.broadcast();

  Stream<List<AchievementBadge>> watchUnlocked() async* {
    final snapshot = await getUnlocked();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<List<AchievementBadge>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <AchievementBadge>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <AchievementBadge>[];
      }

      final items =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    AchievementBadge.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
            ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

      return items;
    } catch (_) {
      await prefs.remove(_storageKey);
      return <AchievementBadge>[];
    }
  }

  Future<List<AchievementBadge>> evaluateMilestones({
    required List<SessionHistoryEntry> history,
  }) async {
    if (history.isEmpty) {
      return <AchievementBadge>[];
    }

    final unlocked = await getUnlocked();
    final unlockedIds = unlocked.map((item) => item.id).toSet();
    final now = DateTime.now().toUtc();

    final newlyUnlocked = <AchievementBadge>[];

    void unlockIfMissing(String id) {
      if (unlockedIds.contains(id)) {
        return;
      }
      final badge = _buildBadge(id: id, unlockedAt: now);
      if (badge == null) {
        return;
      }

      newlyUnlocked.add(badge);
      unlockedIds.add(id);
    }

    unlockIfMissing('first_session');

    if (_distinctDays(history) >= 3) {
      unlockIfMissing('streak_3_days');
    }

    if (history.any((entry) => entry.mode == 'recovery')) {
      unlockIfMissing('recovery_wise');
    }

    final topFive = history.take(5).toList(growable: false);
    if (topFive.length >= 5) {
      final avgFocus =
          topFive.fold<double>(0, (sum, item) => sum + item.focusScore) /
          topFive.length;
      if (avgFocus >= 3.2) {
        unlockIfMissing('focus_guardian');
      }
    }

    if (_distinctDaysWithin(history, const Duration(days: 7)) >= 5) {
      unlockIfMissing('weekly_commitment');
    }

    if (newlyUnlocked.isEmpty) {
      return <AchievementBadge>[];
    }

    final merged = <AchievementBadge>[...newlyUnlocked, ...unlocked]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

    await _persist(merged);
    return newlyUnlocked;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _controller.add(<AchievementBadge>[]);
  }

  AchievementBadge? _buildBadge({
    required String id,
    required DateTime unlockedAt,
  }) {
    switch (id) {
      case 'first_session':
        return AchievementBadge(
          id: id,
          title: 'Bắt đầu hành trình',
          description: 'Bạn đã hoàn thành phiên học đầu tiên.',
          iconKey: 'rocket',
          unlockedAt: unlockedAt,
        );
      case 'streak_3_days':
        return AchievementBadge(
          id: id,
          title: 'Streak 3 ngày',
          description: 'Bạn duy trì nhịp học ít nhất 3 ngày.',
          iconKey: 'local_fire_department',
          unlockedAt: unlockedAt,
        );
      case 'recovery_wise':
        return AchievementBadge(
          id: id,
          title: 'Biết nghỉ đúng lúc',
          description: 'Bạn dùng Recovery Mode một cách lành mạnh.',
          iconKey: 'spa',
          unlockedAt: unlockedAt,
        );
      case 'focus_guardian':
        return AchievementBadge(
          id: id,
          title: 'Người giữ tập trung',
          description: '5 phiên gần nhất có mức focus cao ổn định.',
          iconKey: 'psychology_alt',
          unlockedAt: unlockedAt,
        );
      case 'weekly_commitment':
        return AchievementBadge(
          id: id,
          title: 'Cam kết tuần',
          description: 'Bạn học đều ít nhất 5 ngày trong tuần.',
          iconKey: 'calendar_month',
          unlockedAt: unlockedAt,
        );
      default:
        return null;
    }
  }

  static int _distinctDays(List<SessionHistoryEntry> history) {
    final keys = <String>{};
    for (final entry in history) {
      final local = entry.completedAt.toLocal();
      keys.add('${local.year}-${local.month}-${local.day}');
    }
    return keys.length;
  }

  static int _distinctDaysWithin(
    List<SessionHistoryEntry> history,
    Duration window,
  ) {
    final limit = DateTime.now().toUtc().subtract(window);
    final keys = <String>{};

    for (final entry in history) {
      if (entry.completedAt.isBefore(limit)) {
        continue;
      }
      final local = entry.completedAt.toLocal();
      keys.add('${local.year}-${local.month}-${local.day}');
    }

    return keys.length;
  }

  Future<void> _persist(List<AchievementBadge> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );

    await prefs.setString(_storageKey, raw);
    _controller.add(items);
  }
}
