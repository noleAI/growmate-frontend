import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class BehavioralSignalCollector with WidgetsBindingObserver {
  BehavioralSignalCollector._internal({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final BehavioralSignalCollector _instance =
      BehavioralSignalCollector._internal();

  static BehavioralSignalCollector get instance => _instance;

  final http.Client _httpClient;
  final List<Map<String, dynamic>> _pendingSignals = <Map<String, dynamic>>[];
  final Stopwatch _batchStopwatch = Stopwatch();
  final Stopwatch _idleStopwatch = Stopwatch();
  Future<void> Function(List<Map<String, dynamic>> batch)? _batchSubmitter;

  Timer? _batchTimer;
  Stopwatch? _questionStopwatch;
  Uri? _apiEndpoint;

  bool _isObserverAttached = false;
  bool _isPaused = false;
  bool _collectionEnabled = true;
  bool _responseCaptured = false;

  double? _responseTimeSeconds;
  double? _batchElapsedSecondsOverrideForTest;
  double? _idleElapsedSecondsOverrideForTest;
  int _typedCharsInWindow = 0;
  int _correctionsInWindow = 0;

  void configureEndpoint(String endpoint) {
    _apiEndpoint = Uri.tryParse(endpoint);
    _ensureInitialized();
  }

  void setCollectionEnabled(bool enabled) {
    if (_collectionEnabled == enabled) {
      return;
    }

    _collectionEnabled = enabled;

    if (!_collectionEnabled) {
      _stopCollection();
      return;
    }

    _ensureInitialized();
  }

  void attachBatchSubmitter(
    Future<void> Function(List<Map<String, dynamic>> batch) submitter,
  ) {
    _batchSubmitter = submitter;
    _ensureInitialized();
  }

  void startQuestionTimer() {
    if (!_collectionEnabled) {
      return;
    }

    _ensureInitialized();
    _questionStopwatch = Stopwatch()..start();
    _responseCaptured = false;
    _responseTimeSeconds = null;
    resetIdleTimer();
  }

  void recordKeystroke({int characterCount = 1}) {
    if (!_collectionEnabled) {
      return;
    }

    _ensureInitialized();

    if (characterCount <= 0) {
      return;
    }

    _typedCharsInWindow += characterCount;

    if (!_responseCaptured && _questionStopwatch?.isRunning == true) {
      _responseTimeSeconds =
          _questionStopwatch!.elapsedMicroseconds /
          Duration.microsecondsPerSecond;
      _responseCaptured = true;
    }

    resetIdleTimer();
  }

  void recordCorrection() {
    if (!_collectionEnabled) {
      return;
    }

    _ensureInitialized();
    _correctionsInWindow += 1;
    resetIdleTimer();
  }

  void recordSubmit() {
    if (!_collectionEnabled) {
      return;
    }

    _ensureInitialized();
    resetIdleTimer();

    _collectSnapshot(trigger: 'submit');
    unawaited(_flushBatch());

    _questionStopwatch?.stop();
    _responseCaptured = false;
    _responseTimeSeconds = null;
  }

  void resetIdleTimer() {
    if (!_collectionEnabled) {
      return;
    }

    _ensureInitialized();
    _idleStopwatch
      ..reset()
      ..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_collectionEnabled) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeCollector();
      case AppLifecycleState.paused:
        _pauseCollectorAndFlush();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _ensureInitialized() {
    if (!_collectionEnabled) {
      return;
    }

    if (!_isObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAttached = true;
    }

    if (!_batchStopwatch.isRunning) {
      _batchStopwatch.start();
    }

    if (!_idleStopwatch.isRunning) {
      _idleStopwatch.start();
    }

    if (_batchTimer == null) {
      _startBatchTimer();
    }
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isPaused) {
        return;
      }

      _collectSnapshot(trigger: 'periodic');
      unawaited(_flushBatch());
    });
  }

  void _pauseCollectorAndFlush() {
    _isPaused = true;

    _batchTimer?.cancel();
    _batchTimer = null;

    if (_batchStopwatch.isRunning) {
      _batchStopwatch.stop();
    }
    if (_idleStopwatch.isRunning) {
      _idleStopwatch.stop();
    }

    _collectSnapshot(trigger: 'lifecycle_paused');
    unawaited(_flushBatch());
  }

  void _resumeCollector() {
    _isPaused = false;

    if (!_batchStopwatch.isRunning) {
      _batchStopwatch.start();
    }
    if (!_idleStopwatch.isRunning) {
      _idleStopwatch.start();
    }

    if (_batchTimer == null) {
      _startBatchTimer();
    }
  }

  void _collectSnapshot({required String trigger}) {
    final elapsedSeconds =
        _batchElapsedSecondsOverrideForTest ??
        (_batchStopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);

    final typingSpeed = elapsedSeconds <= 0
        ? 0.0
        : _typedCharsInWindow / elapsedSeconds;

    final correctionRate = _typedCharsInWindow <= 0
        ? 0.0
        : _correctionsInWindow / _typedCharsInWindow;

    final idleSeconds =
        _idleElapsedSecondsOverrideForTest ??
        (_idleStopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);

    _pendingSignals.add({
      'trigger': trigger,
      'timestamp': DateTime.now().toIso8601String(),
      'typingSpeed': typingSpeed,
      'correctionRate': correctionRate,
      'idleTime': idleSeconds,
      'responseTime': _responseTimeSeconds,
      'typedChars': _typedCharsInWindow,
      'corrections': _correctionsInWindow,
    });

    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;

    _batchStopwatch
      ..reset()
      ..start();

    _batchElapsedSecondsOverrideForTest = null;
    _idleElapsedSecondsOverrideForTest = null;
  }

  Future<void> _flushBatch() async {
    if (!_collectionEnabled) {
      return;
    }

    if (_pendingSignals.isEmpty) {
      return;
    }

    final payload = List<Map<String, dynamic>>.from(_pendingSignals);
    _pendingSignals.clear();

    await submitBatchSignals(payload);
  }

  Future<void> submitBatchSignals(List<Map<String, dynamic>> batch) async {
    if (batch.isEmpty) {
      return;
    }

    final submitter = _batchSubmitter;
    if (submitter != null) {
      try {
        await submitter(batch);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'BehavioralSignalCollector delegated submit failed: $error',
          );
          debugPrint('$stackTrace');
        }

        _pendingSignals.insertAll(0, batch);
      }
      return;
    }

    final endpoint = _apiEndpoint;
    if (endpoint == null) {
      if (kDebugMode) {
        debugPrint(
          'BehavioralSignalCollector: API endpoint is not configured, skip submit.',
        );
      }
      return;
    }

    try {
      await _httpClient
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'signals': batch}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('BehavioralSignalCollector submit failed: $error');
        debugPrint('$stackTrace');
      }

      _pendingSignals.insertAll(0, batch);
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_isObserverAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverAttached = false;
    }

    _batchStopwatch.stop();
    _idleStopwatch.stop();
    _questionStopwatch?.stop();
  }

  @visibleForTesting
  void resetForTest() {
    dispose();

    _pendingSignals.clear();

    _batchStopwatch.reset();
    _idleStopwatch.reset();

    _questionStopwatch = null;
    _apiEndpoint = null;
    _batchSubmitter = null;

    _isPaused = false;
    _collectionEnabled = true;
    _responseCaptured = false;
    _responseTimeSeconds = null;
    _batchElapsedSecondsOverrideForTest = null;
    _idleElapsedSecondsOverrideForTest = null;
    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;
  }

  void _stopCollection() {
    _batchTimer?.cancel();
    _batchTimer = null;

    _batchStopwatch.stop();
    _batchStopwatch.reset();

    _idleStopwatch.stop();
    _idleStopwatch.reset();

    _questionStopwatch?.stop();
    _questionStopwatch = null;

    _pendingSignals.clear();
    _typedCharsInWindow = 0;
    _correctionsInWindow = 0;
    _responseCaptured = false;
    _responseTimeSeconds = null;
  }

  @visibleForTesting
  void setElapsedOverridesForTest({
    double? batchElapsedSeconds,
    double? idleElapsedSeconds,
  }) {
    _batchElapsedSecondsOverrideForTest = batchElapsedSeconds;
    _idleElapsedSecondsOverrideForTest = idleElapsedSeconds;
  }
}
