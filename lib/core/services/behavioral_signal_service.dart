import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../features/auth/data/repositories/data_consent_repository.dart';
import '../models/signal_batch.dart';

class BehavioralSignalService with WidgetsBindingObserver {
  BehavioralSignalService._internal();

  static final BehavioralSignalService _instance =
      BehavioralSignalService._internal();

  static BehavioralSignalService get instance => _instance;

  final List<SignalBatch> _pendingBatches = <SignalBatch>[];
  final Stopwatch _windowStopwatch = Stopwatch();
  final Stopwatch _idleStopwatch = Stopwatch();
  final DataConsentRepository _dataConsentRepository =
      DataConsentRepository.instance;

  Future<void> Function(List<SignalBatch> batch)? _batchSubmitter;
  String? Function()? _activeUserKeyResolver;

  Timer? _batchTimer;
  Stopwatch? _questionStopwatch;
  bool _observerAttached = false;
  bool _isPaused = false;
  bool _isCollecting = false;
  // Privacy-first default: collection is disabled until user explicitly opts in.
  bool _collectionEnabled = false;
  bool _hasActiveConsent = false;
  bool _firstInputCaptured = false;
  double _lastIdleSeconds = 0;

  String? _questionId;
  double? _responseTime;
  int _typedCharsInWindow = 0;
  int _correctionsInWindow = 0;

  bool hasHighIdleTime({double thresholdSeconds = 9}) {
    if (!_isCollecting) {
      return false;
    }

    final currentIdleSeconds =
        _idleStopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;

    return currentIdleSeconds >= thresholdSeconds ||
        _lastIdleSeconds >= thresholdSeconds;
  }

  void setCollectionEnabled(bool enabled) {
    if (_collectionEnabled == enabled) {
      return;
    }

    _collectionEnabled = enabled;
    if (_collectionEnabled) {
      unawaited(_syncConsentState(forceRefresh: true));
    }
    if (!_collectionEnabled) {
      _hasActiveConsent = false;
      stop(flush: false);
    }
  }

  void attachBatchSubmitter(
    Future<void> Function(List<SignalBatch> batch) submitter,
  ) {
    _batchSubmitter = submitter;
  }

  void setActiveUserKeyResolver(String? Function()? resolver) {
    _activeUserKeyResolver = resolver;
  }

  void startQuestion({required String questionId}) {
    if (!_collectionEnabled) {
      return;
    }

    unawaited(_startQuestionIfConsented(questionId: questionId));
  }

  Future<void> _startQuestionIfConsented({required String questionId}) async {
    final hasConsent = await _syncConsentState(forceRefresh: true);
    if (!hasConsent || !_collectionEnabled) {
      return;
    }

    _ensureObserver();

    _questionId = questionId;
    _isCollecting = true;
    _isPaused = false;
    _firstInputCaptured = false;
    _responseTime = null;
    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;

    _questionStopwatch = Stopwatch()..start();
    _windowStopwatch
      ..reset()
      ..start();
    _idleStopwatch
      ..reset()
      ..start();

    _startBatchTimer();
  }

  void stop({bool flush = true}) {
    if (!_isCollecting) {
      return;
    }

    if (flush && !_isPaused) {
      _collectSnapshot(trigger: 'stop');
      unawaited(_flush());
    }

    _batchTimer?.cancel();
    _batchTimer = null;

    _windowStopwatch
      ..stop()
      ..reset();
    _idleStopwatch
      ..stop()
      ..reset();
    _questionStopwatch?.stop();
    _questionStopwatch = null;

    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;
    _lastIdleSeconds = 0;
    _responseTime = null;
    _firstInputCaptured = false;
    _questionId = null;
    _isCollecting = false;
    _isPaused = false;
  }

  void registerInteraction() {
    if (!_canCollect) {
      return;
    }

    _idleStopwatch
      ..reset()
      ..start();
  }

  void recordTypingDelta(int deltaChars) {
    if (!_canCollect || deltaChars <= 0) {
      return;
    }

    _typedCharsInWindow += deltaChars;
    _captureResponseTimeIfNeeded();
    registerInteraction();
  }

  void recordCorrectionCount(int corrections) {
    if (!_canCollect || corrections <= 0) {
      return;
    }

    _correctionsInWindow += corrections;
    _captureResponseTimeIfNeeded();
    registerInteraction();
  }

  void recordFocusChanged({required bool hasFocus}) {
    if (!_canCollect) {
      return;
    }

    if (hasFocus) {
      registerInteraction();
      return;
    }

    if (_idleStopwatch.isRunning) {
      _idleStopwatch.stop();
    }
  }

  void markSubmitted() {
    if (!_canCollect) {
      return;
    }

    _collectSnapshot(trigger: 'submit');
    registerInteraction();
    unawaited(_flush());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCollecting || !_collectionEnabled) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pauseCollection();
      case AppLifecycleState.resumed:
        _resumeCollection();
      case AppLifecycleState.detached:
        break;
    }
  }

  void dispose() {
    stop(flush: false);

    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }

    _pendingBatches.clear();
    _batchSubmitter = null;
  }

  bool get _canCollect =>
      _collectionEnabled && _hasActiveConsent && _isCollecting && !_isPaused;

  void _ensureObserver() {
    if (_observerAttached) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_canCollect) {
        return;
      }

      _collectSnapshot(trigger: 'periodic');
      unawaited(_flush());
    });
  }

  void _pauseCollection() {
    _isPaused = true;

    _batchTimer?.cancel();
    _batchTimer = null;

    if (_windowStopwatch.isRunning) {
      _windowStopwatch.stop();
    }
    if (_idleStopwatch.isRunning) {
      _idleStopwatch.stop();
    }

    _collectSnapshot(trigger: 'lifecycle_paused');
    unawaited(_flush());
  }

  void _resumeCollection() {
    if (!_collectionEnabled || !_isCollecting) {
      return;
    }

    _isPaused = false;

    if (!_windowStopwatch.isRunning) {
      _windowStopwatch.start();
    }
    if (!_idleStopwatch.isRunning) {
      _idleStopwatch.start();
    }

    _startBatchTimer();
  }

  void _captureResponseTimeIfNeeded() {
    if (_firstInputCaptured) {
      return;
    }

    final stopwatch = _questionStopwatch;
    if (stopwatch == null || !stopwatch.isRunning) {
      return;
    }

    _responseTime =
        stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _firstInputCaptured = true;
  }

  void _collectSnapshot({required String trigger}) {
    final questionId = _questionId;
    if (questionId == null) {
      return;
    }

    final elapsedSeconds =
        _windowStopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    final typingSpeed = elapsedSeconds <= 0
        ? 0.0
        : _typedCharsInWindow / elapsedSeconds;

    final idleSeconds =
        _idleStopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _lastIdleSeconds = idleSeconds;

    final batch = SignalBatch(
      questionId: questionId,
      typingSpeed: typingSpeed,
      idleTime: idleSeconds,
      correctionRate: _correctionsInWindow,
      responseTime: _responseTime,
      capturedAt: DateTime.now().toUtc(),
      trigger: trigger,
    );

    _pendingBatches.add(batch);

    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;

    _windowStopwatch
      ..reset()
      ..start();

    if (_idleStopwatch.isRunning) {
      _idleStopwatch
        ..reset()
        ..start();
    }
  }

  Future<void> _flush() async {
    if (_pendingBatches.isEmpty) {
      return;
    }

    final hasConsent = await _syncConsentState();
    if (!hasConsent) {
      _pendingBatches.clear();
      stop(flush: false);
      return;
    }

    final batchPayload = List<SignalBatch>.from(_pendingBatches);
    _pendingBatches.clear();

    for (final signal in batchPayload) {
      debugPrint(
        '🔍 Signal Sent: Idle ${signal.idleTime.toStringAsFixed(1)}s, Corrections: ${signal.correctionRate}',
      );
    }

    final submitter = _batchSubmitter;
    if (submitter == null) {
      return;
    }

    try {
      await submitter(batchPayload);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('BehavioralSignalService submit failed: $error');
        debugPrint('$stackTrace');
      }

      _pendingBatches.insertAll(0, batchPayload);
    }
  }

  Future<bool> _syncConsentState({bool forceRefresh = false}) async {
    if (!_collectionEnabled) {
      _hasActiveConsent = false;
      return false;
    }

    try {
      final userKey = _activeUserKeyResolver?.call();
      final hasConsent = await _dataConsentRepository.isAccepted(
        userKey: userKey,
      );
      _hasActiveConsent = hasConsent;
      return hasConsent;
    } catch (_) {
      if (forceRefresh) {
        _hasActiveConsent = false;
      }
      return _hasActiveConsent;
    }
  }
}
