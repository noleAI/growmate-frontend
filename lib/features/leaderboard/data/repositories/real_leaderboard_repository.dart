import '../../../../core/network/rest_api_client.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_badge.dart';
import '../models/xp_add_response.dart';
import 'leaderboard_repository.dart';

/// Real implementation calling the backend REST API.
class RealLeaderboardRepository implements LeaderboardRepository {
  RealLeaderboardRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String period,
    int limit = 20,
  }) async {
    final json = await _client.get(
      '/leaderboard',
      queryParams: {'period': period, 'limit': limit.toString()},
    );
    final rawList = json['leaderboard'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<LeaderboardEntry?> getMyRank({String period = 'weekly'}) async {
    final json = await _client.get(
      '/leaderboard/me',
      queryParams: {'period': period},
    );
    if (json.isEmpty) return null;
    return LeaderboardEntry(
      userId: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] as num?)?.toInt() ?? 0,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<UserBadge>> getAllBadges() async {
    final json = await _client.get('/badges');
    final earned = _parseBadges(json['earned'], isEarned: true);
    final available = _parseBadges(json['available'], isEarned: false);
    return [...earned, ...available];
  }

  @override
  Future<List<UserBadge>> getMyBadges() async {
    final json = await _client.get('/badges');
    return _parseBadges(json['earned'], isEarned: true);
  }

  @override
  Future<XpAddResponse> addXp({
    required String eventType,
    Map<String, dynamic>? extraData,
  }) async {
    final body = <String, dynamic>{'event_type': eventType};
    if (extraData != null) body['extra_data'] = extraData;
    final json = await _client.post('/xp/add', body);
    return XpAddResponse.fromJson(json);
  }

  List<UserBadge> _parseBadges(Object? raw, {required bool isEarned}) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((b) {
          return UserBadge(
            id: (b['badge_type'] ?? '').toString(),
            badgeType: (b['badge_type'] ?? '').toString(),
            badgeName: (b['badge_name'] ?? '').toString(),
            iconEmoji: (b['icon'] ?? '🏅').toString(),
            earnedAt: isEarned && b['earned_at'] != null
                ? DateTime.tryParse(b['earned_at'].toString())
                : null,
            description: (b['description'] ?? '').toString(),
          );
        })
        .toList(growable: false);
  }
}
