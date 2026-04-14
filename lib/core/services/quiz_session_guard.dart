import 'dart:async';

/// Client-side quiz guard: detects spam (rapid answers) and AFK (idle too long).
///
/// - Spam: user answers < [spamThreshold] seconds → triggers warning callback
/// - AFK: user idle > [afkThreshold] → triggers AFK callback
/// - Auto-pauses quiz timer when AFK is detected
class QuizSessionGuard {
  QuizSessionGuard({
    this.spamThreshold = const Duration(seconds: 2),
    this.afkThreshold = const Duration(minutes: 3),
    this.onSpamDetected,
    this.onAfkDetected,
    this.onAfkResume,
  });

  final Duration spamThreshold;
  final Duration afkThreshold;

  final void Function(int consecutiveSpamCount)? onSpamDetected;
  final VoidCallback? onAfkDetected;
  final VoidCallback? onAfkResume;

  DateTime? _lastAnswerTime;
  int _consecutiveSpamCount = 0;
  Timer? _afkTimer;
  bool _isAfk = false;

  /// Call when a new question is displayed.
  void onQuestionShown() {
    _lastAnswerTime = DateTime.now();
    _resetAfkTimer();
  }

  /// Call when user interacts (tap, scroll, type).
  void onUserActivity() {
    if (_isAfk) {
      _isAfk = false;
      onAfkResume?.call();
    }
    _resetAfkTimer();
  }

  /// Call when user submits an answer. Returns true if spam was detected.
  bool onAnswerSubmitted() {
    final now = DateTime.now();

    if (_lastAnswerTime != null) {
      final elapsed = now.difference(_lastAnswerTime!);
      if (elapsed < spamThreshold) {
        _consecutiveSpamCount++;
        if (_consecutiveSpamCount >= 2) {
          onSpamDetected?.call(_consecutiveSpamCount);
        }
        _lastAnswerTime = now;
        _resetAfkTimer();
        return true;
      }
    }

    _consecutiveSpamCount = 0;
    _lastAnswerTime = now;
    _resetAfkTimer();
    return false;
  }

  bool get isAfk => _isAfk;
  int get consecutiveSpamCount => _consecutiveSpamCount;

  void _resetAfkTimer() {
    _afkTimer?.cancel();
    _afkTimer = Timer(afkThreshold, () {
      _isAfk = true;
      onAfkDetected?.call();
    });
  }

  void dispose() {
    _afkTimer?.cancel();
  }
}

typedef VoidCallback = void Function();
