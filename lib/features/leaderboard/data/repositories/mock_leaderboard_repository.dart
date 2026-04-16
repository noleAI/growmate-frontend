import '../models/leaderboard_entry.dart';
import '../models/user_badge.dart';
import '../models/xp_add_response.dart';
import 'leaderboard_repository.dart';

/// Mock implementation — 20 users giả lập + 10 badge definitions.
class MockLeaderboardRepository implements LeaderboardRepository {
  static const String _myUserId = 'me_user_001';

  static final List<LeaderboardEntry> _allEntries = [
    const LeaderboardEntry(
      userId: 'user_001',
      displayName: 'Minh Tuấn',
      rank: 1,
      weeklyXp: 1240,
      totalXp: 8920,
      currentStreak: 21,
      badgeCount: 2,
      longestStreak: 21,
    ),
    const LeaderboardEntry(
      userId: 'user_002',
      displayName: 'Lan Anh',
      rank: 2,
      weeklyXp: 1105,
      totalXp: 7650,
      currentStreak: 14,
      badgeCount: 1,
      longestStreak: 14,
    ),
    const LeaderboardEntry(
      userId: 'user_003',
      displayName: 'Quốc Bảo',
      rank: 3,
      weeklyXp: 980,
      totalXp: 6340,
      currentStreak: 7,
      badgeCount: 2,
      longestStreak: 10,
    ),
    const LeaderboardEntry(
      userId: 'user_004',
      displayName: 'Thùy Linh',
      rank: 4,
      weeklyXp: 870,
      totalXp: 5820,
      currentStreak: 5,
      badgeCount: 1,
    ),
    const LeaderboardEntry(
      userId: 'user_005',
      displayName: 'Hữu Nam',
      rank: 5,
      weeklyXp: 760,
      totalXp: 5100,
      currentStreak: 9,
    ),
    const LeaderboardEntry(
      userId: 'user_006',
      displayName: 'Khánh Linh',
      rank: 6,
      weeklyXp: 720,
      totalXp: 4800,
      currentStreak: 3,
    ),
    const LeaderboardEntry(
      userId: 'user_007',
      displayName: 'Việt Hoàng',
      rank: 7,
      weeklyXp: 680,
      totalXp: 4500,
      currentStreak: 6,
    ),
    const LeaderboardEntry(
      userId: 'user_008',
      displayName: 'Ngọc Mai',
      rank: 8,
      weeklyXp: 640,
      totalXp: 4200,
      currentStreak: 2,
    ),
    const LeaderboardEntry(
      userId: 'user_009',
      displayName: 'Đức Thịnh',
      rank: 9,
      weeklyXp: 610,
      totalXp: 3900,
      currentStreak: 4,
    ),
    const LeaderboardEntry(
      userId: 'user_010',
      displayName: 'Bảo Châu',
      rank: 10,
      weeklyXp: 580,
      totalXp: 3600,
      currentStreak: 1,
    ),
    const LeaderboardEntry(
      userId: 'user_011',
      displayName: 'Trọng Hiếu',
      rank: 11,
      weeklyXp: 550,
      totalXp: 3300,
      currentStreak: 8,
    ),
    const LeaderboardEntry(
      userId: _myUserId,
      displayName: 'Bạn',
      rank: 12,
      weeklyXp: 520,
      totalXp: 3100,
      currentStreak: 3,
      badgeCount: 1,
    ),
    const LeaderboardEntry(
      userId: 'user_013',
      displayName: 'Thanh Hương',
      rank: 13,
      weeklyXp: 490,
      totalXp: 2900,
      currentStreak: 2,
    ),
    const LeaderboardEntry(
      userId: 'user_014',
      displayName: 'Gia Huy',
      rank: 14,
      weeklyXp: 460,
      totalXp: 2700,
      currentStreak: 1,
    ),
    const LeaderboardEntry(
      userId: 'user_015',
      displayName: 'Phương Thảo',
      rank: 15,
      weeklyXp: 430,
      totalXp: 2500,
      currentStreak: 5,
    ),
    const LeaderboardEntry(
      userId: 'user_016',
      displayName: 'Nhật Minh',
      rank: 16,
      weeklyXp: 400,
      totalXp: 2200,
      currentStreak: 3,
    ),
    const LeaderboardEntry(
      userId: 'user_017',
      displayName: 'Hải Yến',
      rank: 17,
      weeklyXp: 370,
      totalXp: 2000,
      currentStreak: 0,
    ),
    const LeaderboardEntry(
      userId: 'user_018',
      displayName: 'Xuân Trường',
      rank: 18,
      weeklyXp: 340,
      totalXp: 1800,
      currentStreak: 2,
    ),
    const LeaderboardEntry(
      userId: 'user_019',
      displayName: 'Diệu Linh',
      rank: 19,
      weeklyXp: 310,
      totalXp: 1600,
      currentStreak: 1,
    ),
    const LeaderboardEntry(
      userId: 'user_020',
      displayName: 'Văn Đức',
      rank: 20,
      weeklyXp: 280,
      totalXp: 1400,
      currentStreak: 0,
    ),
  ];

  static final List<UserBadge> _allBadges = [
    UserBadge(
      id: 'badge_streak_7',
      badgeType: 'streak_7',
      badgeName: 'Kiên Trì 7 Ngày',
      iconEmoji: '🔥',
      earnedAt: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Học liên tiếp 7 ngày không ngừng',
      unlockCondition: 'Đạt streak 7 ngày',
    ),
    const UserBadge(
      id: 'badge_streak_14',
      badgeType: 'streak_14',
      badgeName: 'Bền Bỉ 2 Tuần',
      iconEmoji: '⚡',
      description: 'Học liên tiếp 14 ngày không ngừng',
      unlockCondition: 'Đạt streak 14 ngày',
    ),
    const UserBadge(
      id: 'badge_streak_21',
      badgeType: 'streak_21',
      badgeName: 'Huyền Thoại 21 Ngày',
      iconEmoji: '💎',
      description: 'Học liên tiếp 21 ngày — thành thói quen rồi đó!',
      unlockCondition: 'Đạt streak 21 ngày',
    ),
    const UserBadge(
      id: 'badge_top_3',
      badgeType: 'top_3',
      badgeName: 'Top 3',
      iconEmoji: '🥇',
      description: 'Lọt vào top 3 bảng xếp hạng tuần',
      unlockCondition: 'Xếp hạng top 3 trong tuần',
    ),
    const UserBadge(
      id: 'badge_top_10',
      badgeType: 'top_10',
      badgeName: 'Top 10',
      iconEmoji: '⭐',
      description: 'Lọt vào top 10 bảng xếp hạng tuần',
      unlockCondition: 'Xếp hạng top 10 trong tuần',
    ),
    const UserBadge(
      id: 'badge_mastery_chain_rule',
      badgeType: 'mastery_chain_rule',
      badgeName: 'Thần Chain Rule',
      iconEmoji: '🔗',
      description: 'Đạt accuracy >80% cho hàm hợp',
      unlockCondition: 'Độ chính xác >80% cho Chain Rule',
    ),
    const UserBadge(
      id: 'badge_mastery_trig',
      badgeType: 'mastery_trig',
      badgeName: 'Master Lượng Giác',
      iconEmoji: '📐',
      description: 'Đạt accuracy >80% cho đạo hàm lượng giác',
      unlockCondition: 'Độ chính xác >80% cho Lượng giác',
    ),
    const UserBadge(
      id: 'badge_speed_demon',
      badgeType: 'speed_demon',
      badgeName: 'Tốc Biến',
      iconEmoji: '⚡',
      description: 'Hoàn thành quiz <5 phút với accuracy >90%',
      unlockCondition: 'Quiz <5 phút, accuracy >90%',
    ),
    const UserBadge(
      id: 'badge_perfect_week',
      badgeType: 'perfect_week',
      badgeName: 'Tuần Hoàn Hảo',
      iconEmoji: '🌟',
      description: 'Đạt 100% bài đúng trong cả tuần',
      unlockCondition: '100% accuracy trong 1 tuần',
    ),
    const UserBadge(
      id: 'badge_first_quiz',
      badgeType: 'first_quiz',
      badgeName: 'Bắt Đầu Hành Trình',
      iconEmoji: '🌱',
      earnedAt: null, // will be overridden in getMyBadges
      description: 'Hoàn thành quiz đầu tiên',
      unlockCondition: 'Hoàn thành 1 quiz',
    ),
  ];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String period,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _allEntries.take(limit).toList(growable: false);
  }

  @override
  Future<LeaderboardEntry?> getMyRank({String period = 'weekly'}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allEntries.firstWhere(
      (e) => e.userId == _myUserId,
      orElse: () => _allEntries.last,
    );
  }

  @override
  Future<List<UserBadge>> getAllBadges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<UserBadge>.from(_allBadges);
  }

  @override
  Future<List<UserBadge>> getMyBadges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Trả về các badges mà user đã unlock (earnedAt != null)
    return _allBadges.where((b) => b.isUnlocked).toList(growable: false);
  }

  @override
  Future<XpAddResponse> addXp({
    required String eventType,
    Map<String, dynamic>? extraData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    const mockXp = 10;
    final idx = _allEntries.indexWhere((e) => e.userId == _myUserId);
    if (idx >= 0) {
      final me = _allEntries[idx];
      _allEntries[idx] = me.copyWith(
        weeklyXp: me.weeklyXp + mockXp,
        totalXp: me.totalXp + mockXp,
      );
    }
    final me = idx >= 0 ? _allEntries[idx] : null;
    return XpAddResponse(
      xpAdded: mockXp,
      weeklyXp: me?.weeklyXp ?? mockXp,
      totalXp: me?.totalXp ?? mockXp,
      currentStreak: me?.currentStreak ?? 0,
      newBadges: const [],
    );
  }
}
