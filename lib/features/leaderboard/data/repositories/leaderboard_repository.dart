import '../models/leaderboard_entry.dart';
import '../models/user_badge.dart';
import '../models/xp_add_response.dart';

/// Abstract interface cho leaderboard data.
///
/// Swap Mock → Real bằng cách thay implementation trong DI.
abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String period, // 'weekly' | 'monthly' | 'all_time'
    int limit = 20,
  });

  Future<LeaderboardEntry?> getMyRank({String period = 'weekly'});

  Future<List<UserBadge>> getAllBadges();

  Future<List<UserBadge>> getMyBadges();

  /// Cộng XP cho user hiện tại. Trả về thông tin XP/streak/badge mới.
  ///
  /// [eventType]: `correct_answer`, `daily_login`, `complete_quiz`, `perfect_score`.
  Future<XpAddResponse> addXp({
    required String eventType,
    Map<String, dynamic>? extraData,
  });
}
