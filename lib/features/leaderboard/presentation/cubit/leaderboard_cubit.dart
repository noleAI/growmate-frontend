import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/xp_add_response.dart';
import '../../data/repositories/leaderboard_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit({required LeaderboardRepository repository})
    : _repository = repository,
      super(const LeaderboardState());

  final LeaderboardRepository _repository;
  int _rankingRequestId = 0;
  int _badgesRequestId = 0;

  Future<void> loadLeaderboard({String period = 'weekly'}) async {
    final requestId = ++_rankingRequestId;
    emit(
      state.copyWith(
        selectedPeriod: period,
        rankingStatus: LeaderboardLoadStatus.loading,
        rankingError: null,
      ),
    );

    try {
      final entriesFuture = _repository.getLeaderboard(period: period);
      final myRankFuture = _repository.getMyRank(period: period);

      final entries = await entriesFuture;
      final myRank = await myRankFuture;

      if (requestId != _rankingRequestId) {
        return;
      }

      emit(
        state.copyWith(
          entries: entries,
          selectedPeriod: period,
          myRank: myRank,
          rankingStatus: LeaderboardLoadStatus.success,
          rankingError: null,
        ),
      );
    } catch (e) {
      if (requestId != _rankingRequestId) {
        return;
      }

      emit(
        state.copyWith(
          selectedPeriod: period,
          rankingStatus: LeaderboardLoadStatus.failure,
          rankingError: e.toString(),
        ),
      );
    }
  }

  Future<void> switchPeriod(String period) async {
    await loadLeaderboard(period: period);
  }

  Future<void> loadBadges({bool force = false}) async {
    if (!force &&
        state.badgesStatus == LeaderboardLoadStatus.success &&
        state.badges.isNotEmpty) {
      return;
    }

    final requestId = ++_badgesRequestId;
    emit(
      state.copyWith(
        badgesStatus: LeaderboardLoadStatus.loading,
        badgesError: null,
      ),
    );

    try {
      final allBadges = await _repository.getAllBadges();
      final myBadges = await _repository.getMyBadges();

      if (requestId != _badgesRequestId) {
        return;
      }

      emit(
        state.copyWith(
          badges: allBadges,
          myBadges: myBadges,
          badgesStatus: LeaderboardLoadStatus.success,
          badgesError: null,
        ),
      );
    } catch (e) {
      if (requestId != _badgesRequestId) {
        return;
      }

      emit(
        state.copyWith(
          badgesStatus: LeaderboardLoadStatus.failure,
          badgesError: e.toString(),
        ),
      );
    }
  }

  /// Cộng XP sau khi trả lời đúng, cập nhật state từ server response.
  Future<XpAddResponse?> addXp({
    required String eventType,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final response = await _repository.addXp(
        eventType: eventType,
        extraData: extraData,
      );
      final current = state;
      if (current.myRank != null) {
        emit(
          current.copyWith(
            myRank: current.myRank!.copyWith(
              weeklyXp: response.weeklyXp,
              totalXp: response.totalXp,
              currentStreak: response.currentStreak,
            ),
          ),
        );
      }
      if (state.rankingStatus == LeaderboardLoadStatus.success) {
        await loadLeaderboard(period: state.selectedPeriod);
      }
      return response;
    } catch (_) {
      return null;
    }
  }
}
