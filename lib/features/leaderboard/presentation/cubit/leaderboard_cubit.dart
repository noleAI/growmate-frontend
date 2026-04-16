import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/xp_add_response.dart';
import '../../data/repositories/leaderboard_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit({required LeaderboardRepository repository})
    : _repository = repository,
      super(const LeaderboardInitial());

  final LeaderboardRepository _repository;

  Future<void> loadLeaderboard({String period = 'weekly'}) async {
    emit(const LeaderboardLoading());
    try {
      final entries = await _repository.getLeaderboard(period: period);
      final myRank = await _repository.getMyRank(period: period);
      final allBadges = await _repository.getAllBadges();
      final myBadges = await _repository.getMyBadges();
      emit(
        LeaderboardLoaded(
          entries: entries,
          selectedPeriod: period,
          myRank: myRank,
          badges: allBadges,
          myBadges: myBadges,
        ),
      );
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> switchPeriod(String period) async {
    final current = state;
    if (current is LeaderboardLoaded) {
      emit(current.copyWith(selectedPeriod: period));
    }
    try {
      final entries = await _repository.getLeaderboard(period: period);
      final current2 = state;
      if (current2 is LeaderboardLoaded) {
        emit(current2.copyWith(entries: entries, selectedPeriod: period));
      }
    } catch (_) {}
  }

  Future<void> loadBadges() async {
    try {
      final allBadges = await _repository.getAllBadges();
      final myBadges = await _repository.getMyBadges();
      final current = state;
      if (current is LeaderboardLoaded) {
        emit(current.copyWith(badges: allBadges, myBadges: myBadges));
      }
    } catch (_) {}
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
      if (current is LeaderboardLoaded && current.myRank != null) {
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
      return response;
    } catch (_) {
      return null;
    }
  }
}
