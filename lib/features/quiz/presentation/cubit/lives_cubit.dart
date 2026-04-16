import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/lives_repository.dart';
import 'lives_state.dart';

class LivesCubit extends Cubit<LivesState> {
  LivesCubit({required LivesRepository repository})
    : _repository = repository,
      super(const LivesInitial());

  final LivesRepository _repository;
  Timer? _countdownTimer;

  Future<void> loadLives() async {
    try {
      final info = await _repository.getLives();
      emit(LivesLoaded(info: info));
      if (!info.isFull) {
        startRegenCountdown();
      }
    } catch (e) {
      emit(LivesError(e.toString()));
    }
  }

  Future<void> loseLife() async {
    try {
      final info = await _repository.loseLife();
      emit(LivesLoaded(info: info));
      if (!info.isFull) {
        startRegenCountdown();
      }
    } catch (_) {}
  }

  bool get canPlay {
    final current = state;
    if (current is LivesLoaded) return current.canPlay;
    return true; // default: bật
  }

  void startRegenCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onRegenTick();
    });
  }

  void _onRegenTick() {
    final current = state;
    if (current is! LivesLoaded) return;

    final nextRegen = current.info.nextRegenIn;
    if (nextRegen == null || nextRegen <= Duration.zero) {
      // Thời gian hồi sinh đã đến
      _repository.restoreLife().then((info) {
        if (!isClosed) {
          emit(
            LivesLoaded(
              info: info,
              countdownDisplay: _format(info.nextRegenIn),
            ),
          );
          if (info.isFull) _countdownTimer?.cancel();
        }
      });
      return;
    }

    final updated = current.info.copyWith(
      nextRegenIn: nextRegen - const Duration(seconds: 1),
    );
    emit(
      current.copyWith(
        info: updated,
        countdownDisplay: _format(updated.nextRegenIn),
      ),
    );
  }

  String? _format(Duration? d) {
    if (d == null) return null;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
