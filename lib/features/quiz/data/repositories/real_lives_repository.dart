import 'dart:async';

import '../../../../core/network/rest_api_client.dart';
import '../models/lives_info.dart';
import 'lives_repository.dart';

/// Real implementation calling the backend REST API.
class RealLivesRepository implements LivesRepository {
  RealLivesRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;
  final StreamController<LivesInfo> _controller =
      StreamController<LivesInfo>.broadcast();

  @override
  Future<LivesInfo> getLives() async {
    final json = await _client.get('/lives');
    return _parseLivesResponse(json);
  }

  @override
  Future<LivesInfo> loseLife() async {
    final json = await _client.post('/lives/lose', const {});
    final info = _parseLivesResponse(json);
    _controller.add(info);
    return info;
  }

  @override
  Future<LivesInfo> restoreLife() async {
    final json = await _client.post('/lives/regen', const {});
    final info = _parseLivesResponse(json);
    _controller.add(info);
    return info;
  }

  @override
  Stream<LivesInfo> watchLives() => _controller.stream;

  void dispose() {
    _controller.close();
  }

  /// Parse the backend response shape:
  /// `{current, max, can_play, next_regen_at, next_regen_in_seconds}`
  LivesInfo _parseLivesResponse(Map<String, dynamic> json) {
    final current =
        (json['current'] ?? json['remaining'] ?? json['current_lives']) as int?;
    final max = (json['max'] ?? json['max_lives']) as int?;
    final nextRegenInSeconds = json['next_regen_in_seconds'] as int?;

    return LivesInfo(
      currentLives: current ?? 3,
      maxLives: max ?? 3,
      nextRegenIn: nextRegenInSeconds != null
          ? Duration(seconds: nextRegenInSeconds)
          : null,
    );
  }
}
