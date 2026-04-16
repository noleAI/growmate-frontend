import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_badge.dart';

sealed class LeaderboardState {
  const LeaderboardState();
}

final class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

final class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

final class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded({
    required this.entries,
    required this.selectedPeriod,
    this.myRank,
    this.badges = const <UserBadge>[],
    this.myBadges = const <UserBadge>[],
  });

  final List<LeaderboardEntry> entries;
  final String selectedPeriod; // 'weekly' | 'monthly' | 'all_time'
  final LeaderboardEntry? myRank;
  final List<UserBadge> badges;
  final List<UserBadge> myBadges;

  LeaderboardLoaded copyWith({
    List<LeaderboardEntry>? entries,
    String? selectedPeriod,
    LeaderboardEntry? myRank,
    List<UserBadge>? badges,
    List<UserBadge>? myBadges,
  }) {
    return LeaderboardLoaded(
      entries: entries ?? this.entries,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      myRank: myRank ?? this.myRank,
      badges: badges ?? this.badges,
      myBadges: myBadges ?? this.myBadges,
    );
  }
}

final class LeaderboardError extends LeaderboardState {
  const LeaderboardError(this.message);
  final String message;
}
