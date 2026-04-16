import '../../data/models/lives_info.dart';

sealed class LivesState {
  const LivesState();
}

final class LivesInitial extends LivesState {
  const LivesInitial();
}

final class LivesLoaded extends LivesState {
  const LivesLoaded({required this.info, this.countdownDisplay});

  final LivesInfo info;

  /// Countdown hiển thị dạng "HH:mm:ss"
  final String? countdownDisplay;

  bool get canPlay => info.canPlay;

  LivesLoaded copyWith({LivesInfo? info, String? countdownDisplay}) {
    return LivesLoaded(
      info: info ?? this.info,
      countdownDisplay: countdownDisplay ?? this.countdownDisplay,
    );
  }
}

final class LivesError extends LivesState {
  const LivesError(this.message);
  final String message;
}
