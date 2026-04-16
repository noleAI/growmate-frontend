import 'dart:async';

import '../models/lives_info.dart';
import 'lives_repository.dart';

/// Mock implementation — 3 tim, giảm khi gọi loseLife().
///
/// Hồi sinh 1 tim sau 8 giờ (mock: 8 giây để dễ test).
class MockLivesRepository implements LivesRepository {
  static const int _maxLives = 3;
  static const Duration _regenDuration = Duration(hours: 8);

  int _currentLives = _maxLives;
  DateTime? _lastLifeLostAt;

  final StreamController<LivesInfo> _controller =
      StreamController<LivesInfo>.broadcast();

  @override
  Future<LivesInfo> getLives() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _buildInfo();
  }

  @override
  Future<LivesInfo> loseLife() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentLives > 0) {
      _currentLives--;
      _lastLifeLostAt = DateTime.now();
    }
    final info = _buildInfo();
    _controller.add(info);
    return info;
  }

  @override
  Future<LivesInfo> restoreLife() async {
    if (_currentLives < _maxLives) {
      _currentLives++;
    }
    final info = _buildInfo();
    _controller.add(info);
    return info;
  }

  @override
  Stream<LivesInfo> watchLives() => _controller.stream;

  LivesInfo _buildInfo() {
    Duration? nextRegenIn;
    final lost = _lastLifeLostAt;
    if (_currentLives < _maxLives && lost != null) {
      final elapsed = DateTime.now().difference(lost);
      final remaining = _regenDuration - elapsed;
      nextRegenIn = remaining.isNegative ? Duration.zero : remaining;
    }

    return LivesInfo(
      currentLives: _currentLives,
      maxLives: _maxLives,
      lastLifeLostAt: _lastLifeLostAt,
      nextRegenIn: nextRegenIn,
    );
  }

  void dispose() {
    _controller.close();
  }
}
