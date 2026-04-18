import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_badge.dart';

enum LeaderboardLoadStatus { initial, loading, success, failure }

class LeaderboardState {
  static const Object _unset = Object();

  const LeaderboardState({
    this.entries = const <LeaderboardEntry>[],
    this.selectedPeriod = 'weekly',
    this.myRank,
    this.badges = const <UserBadge>[],
    this.myBadges = const <UserBadge>[],
    this.rankingStatus = LeaderboardLoadStatus.initial,
    this.badgesStatus = LeaderboardLoadStatus.initial,
    this.rankingError,
    this.badgesError,
  });

  final List<LeaderboardEntry> entries;
  final String selectedPeriod; // 'weekly' | 'monthly' | 'all_time'
  final LeaderboardEntry? myRank;
  final List<UserBadge> badges;
  final List<UserBadge> myBadges;
  final LeaderboardLoadStatus rankingStatus;
  final LeaderboardLoadStatus badgesStatus;
  final String? rankingError;
  final String? badgesError;

  bool get isRankingLoading => rankingStatus == LeaderboardLoadStatus.loading;
  bool get isRankingFailed => rankingStatus == LeaderboardLoadStatus.failure;
  bool get isBadgesLoading => badgesStatus == LeaderboardLoadStatus.loading;
  bool get isBadgesFailed => badgesStatus == LeaderboardLoadStatus.failure;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    String? selectedPeriod,
    Object? myRank = _unset,
    List<UserBadge>? badges,
    List<UserBadge>? myBadges,
    LeaderboardLoadStatus? rankingStatus,
    LeaderboardLoadStatus? badgesStatus,
    Object? rankingError = _unset,
    Object? badgesError = _unset,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      myRank: identical(myRank, _unset)
          ? this.myRank
          : myRank as LeaderboardEntry?,
      badges: badges ?? this.badges,
      myBadges: myBadges ?? this.myBadges,
      rankingStatus: rankingStatus ?? this.rankingStatus,
      badgesStatus: badgesStatus ?? this.badgesStatus,
      rankingError: identical(rankingError, _unset)
          ? this.rankingError
          : rankingError as String?,
      badgesError: identical(badgesError, _unset)
          ? this.badgesError
          : badgesError as String?,
    );
  }
}
