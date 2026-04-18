import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/inspection_ops_models.dart';
import '../../data/repositories/inspection_ops_repository.dart';
import '../../domain/inspection_runtime_store.dart';

const Object _runtimeErrorNoChange = Object();

class InspectionBelief extends Equatable {
  const InspectionBelief({required this.topic, required this.ratio});

  final String topic;
  final double ratio;

  String get percentageLabel => '${(ratio * 100).toStringAsFixed(0)}%';

  @override
  List<Object?> get props => <Object?>[topic, ratio];
}

class InspectionDecisionLog extends Equatable {
  const InspectionDecisionLog({
    required this.action,
    required this.reason,
    required this.source,
    required this.createdAt,
    this.uncertaintyScore,
  });

  final String action;
  final String reason;
  final String source;
  final DateTime createdAt;
  final double? uncertaintyScore;

  @override
  List<Object?> get props => <Object?>[
    action,
    reason,
    source,
    createdAt,
    uncertaintyScore,
  ];
}

class InspectionState extends Equatable {
  const InspectionState({
    required this.devModeEnabled,
    required this.isStreaming,
    required this.beliefs,
    required this.planSteps,
    required this.mentalStateLabel,
    required this.mentalStateHint,
    required this.confidenceScore,
    required this.uncertaintyScore,
    required this.qValues,
    required this.decisionLogs,
    required this.updatedAt,
    required this.runtimeMetrics,
    required this.runtimeAlerts,
    required this.runtimeUpdatedAt,
    required this.runtimeFromServer,
    required this.runtimeLoading,
    required this.runtimeErrorMessage,
  });

  final bool devModeEnabled;
  final bool isStreaming;
  final List<InspectionBelief> beliefs;
  final List<String> planSteps;
  final String mentalStateLabel;
  final String mentalStateHint;
  final double confidenceScore;
  final double uncertaintyScore;
  final Map<String, double> qValues;
  final List<InspectionDecisionLog> decisionLogs;
  final DateTime updatedAt;
  final Map<String, int> runtimeMetrics;
  final List<InspectionRuntimeAlertItem> runtimeAlerts;
  final DateTime runtimeUpdatedAt;
  final bool runtimeFromServer;
  final bool runtimeLoading;
  final String? runtimeErrorMessage;

  bool get canInspect => devModeEnabled;

  factory InspectionState.initial() {
    final snapshot = InspectionRuntimeSnapshot.initial();
    return InspectionState(
      devModeEnabled: false,
      isStreaming: false,
      beliefs: snapshot.beliefs
          .map((item) => InspectionBelief(topic: item.topic, ratio: item.ratio))
          .toList(growable: false),
      planSteps: snapshot.planSteps,
      mentalStateLabel: snapshot.mentalStateLabel,
      mentalStateHint: snapshot.mentalStateHint,
      confidenceScore: snapshot.confidenceScore,
      uncertaintyScore: snapshot.uncertaintyScore,
      qValues: snapshot.qValues,
      decisionLogs: const <InspectionDecisionLog>[],
      updatedAt: snapshot.updatedAt,
      runtimeMetrics: const <String, int>{},
      runtimeAlerts: const <InspectionRuntimeAlertItem>[],
      runtimeUpdatedAt: snapshot.updatedAt,
      runtimeFromServer: false,
      runtimeLoading: false,
      runtimeErrorMessage: null,
    );
  }

  InspectionState copyWith({
    bool? devModeEnabled,
    bool? isStreaming,
    List<InspectionBelief>? beliefs,
    List<String>? planSteps,
    String? mentalStateLabel,
    String? mentalStateHint,
    double? confidenceScore,
    double? uncertaintyScore,
    Map<String, double>? qValues,
    List<InspectionDecisionLog>? decisionLogs,
    DateTime? updatedAt,
    Map<String, int>? runtimeMetrics,
    List<InspectionRuntimeAlertItem>? runtimeAlerts,
    DateTime? runtimeUpdatedAt,
    bool? runtimeFromServer,
    bool? runtimeLoading,
    Object? runtimeErrorMessage = _runtimeErrorNoChange,
  }) {
    return InspectionState(
      devModeEnabled: devModeEnabled ?? this.devModeEnabled,
      isStreaming: isStreaming ?? this.isStreaming,
      beliefs: beliefs ?? this.beliefs,
      planSteps: planSteps ?? this.planSteps,
      mentalStateLabel: mentalStateLabel ?? this.mentalStateLabel,
      mentalStateHint: mentalStateHint ?? this.mentalStateHint,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      uncertaintyScore: uncertaintyScore ?? this.uncertaintyScore,
      qValues: qValues ?? this.qValues,
      decisionLogs: decisionLogs ?? this.decisionLogs,
      updatedAt: updatedAt ?? this.updatedAt,
      runtimeMetrics: runtimeMetrics ?? this.runtimeMetrics,
      runtimeAlerts: runtimeAlerts ?? this.runtimeAlerts,
      runtimeUpdatedAt: runtimeUpdatedAt ?? this.runtimeUpdatedAt,
      runtimeFromServer: runtimeFromServer ?? this.runtimeFromServer,
      runtimeLoading: runtimeLoading ?? this.runtimeLoading,
      runtimeErrorMessage: identical(runtimeErrorMessage, _runtimeErrorNoChange)
          ? this.runtimeErrorMessage
          : runtimeErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    devModeEnabled,
    isStreaming,
    beliefs,
    planSteps,
    mentalStateLabel,
    mentalStateHint,
    confidenceScore,
    uncertaintyScore,
    qValues,
    decisionLogs,
    updatedAt,
    runtimeMetrics,
    runtimeAlerts,
    runtimeUpdatedAt,
    runtimeFromServer,
    runtimeLoading,
    runtimeErrorMessage,
  ];
}

class InspectionCubit extends Cubit<InspectionState> {
  InspectionCubit({
    FlutterSecureStorage? secureStorage,
    InspectionRuntimeStore? runtimeStore,
    InspectionOpsRepository? inspectionOpsRepository,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _runtimeStore = runtimeStore ?? InspectionRuntimeStore.instance,
       _inspectionOpsRepository = inspectionOpsRepository,
       super(InspectionState.initial()) {
    unawaited(loadDevMode());

    _runtimeSubscription = _runtimeStore.stream.listen(_syncFromRuntime);
    _lastRuntimeSnapshot = _runtimeStore.snapshot;
    _syncFromRuntime(_lastRuntimeSnapshot);
    unawaited(_refreshRuntimeOps(silent: true));
  }

  static const String _devModeKey = 'inspection_dev_mode_enabled_v1';
  static const Duration _runtimePollInterval = Duration(seconds: 10);

  final FlutterSecureStorage _secureStorage;
  final InspectionRuntimeStore _runtimeStore;
  final InspectionOpsRepository? _inspectionOpsRepository;

  StreamSubscription<InspectionRuntimeSnapshot>? _runtimeSubscription;
  Timer? _runtimePollingTimer;
  late InspectionRuntimeSnapshot _lastRuntimeSnapshot;

  Future<void> loadDevMode() async {
    try {
      final stored = await _secureStorage.read(key: _devModeKey);
      emit(state.copyWith(devModeEnabled: stored == 'true'));
    } catch (_) {
      emit(state.copyWith(devModeEnabled: false));
    }
  }

  Future<void> setDevMode(bool enabled) async {
    await _secureStorage.write(key: _devModeKey, value: enabled.toString());
    emit(state.copyWith(devModeEnabled: enabled));
  }

  void startLiveSync() {
    if (state.isStreaming) {
      return;
    }

    emit(state.copyWith(isStreaming: true));
    _syncFromRuntime(_runtimeStore.snapshot);
    unawaited(_refreshRuntimeOps(silent: false));
    _startRuntimePolling();
  }

  void stopLiveSync() {
    if (!state.isStreaming) {
      return;
    }

    _runtimePollingTimer?.cancel();
    _runtimePollingTimer = null;
    emit(state.copyWith(isStreaming: false));
  }

  void refreshNow() {
    _syncFromRuntime(_runtimeStore.snapshot);
    unawaited(_refreshRuntimeOps(silent: false));
  }

  void _startRuntimePolling() {
    _runtimePollingTimer?.cancel();
    _runtimePollingTimer = Timer.periodic(_runtimePollInterval, (_) {
      if (!state.isStreaming || isClosed) {
        return;
      }

      unawaited(_refreshRuntimeOps(silent: true));
    });
  }

  Future<void> _refreshRuntimeOps({required bool silent}) async {
    if (_inspectionOpsRepository == null) {
      _emitRuntimeFallback(errorMessage: null);
      return;
    }

    if (!silent) {
      emit(state.copyWith(runtimeLoading: true));
    }

    try {
      final metricsSnapshot = await _inspectionOpsRepository
          .getRuntimeMetrics();
      final alertsSnapshot = await _inspectionOpsRepository.getRuntimeAlerts();
      final mergedMetrics = metricsSnapshot.metrics.isNotEmpty
          ? metricsSnapshot.metrics
          : alertsSnapshot.metrics;

      emit(
        state.copyWith(
          runtimeMetrics: mergedMetrics,
          runtimeAlerts: alertsSnapshot.alerts,
          runtimeUpdatedAt: _pickLatestTimestamp(
            metricsSnapshot.observedAt,
            alertsSnapshot.observedAt,
          ),
          runtimeFromServer: true,
          runtimeLoading: false,
          runtimeErrorMessage: null,
        ),
      );
    } catch (error) {
      _emitRuntimeFallback(errorMessage: _toRuntimeErrorMessage(error));
    }
  }

  void _emitRuntimeFallback({required String? errorMessage}) {
    final snapshot = _lastRuntimeSnapshot;

    emit(
      state.copyWith(
        runtimeMetrics: _buildLocalRuntimeMetrics(snapshot),
        runtimeAlerts: _buildLocalRuntimeAlerts(snapshot),
        runtimeUpdatedAt: snapshot.updatedAt,
        runtimeFromServer: false,
        runtimeLoading: false,
        runtimeErrorMessage: errorMessage,
      ),
    );
  }

  static DateTime _pickLatestTimestamp(DateTime first, DateTime second) {
    return first.isAfter(second) ? first : second;
  }

  Map<String, int> _buildLocalRuntimeMetrics(
    InspectionRuntimeSnapshot snapshot,
  ) {
    return <String, int>{
      'belief_topics_count': snapshot.beliefs.length,
      'plan_steps_count': snapshot.planSteps.length,
      'decision_logs_count': snapshot.decisionLogs.length,
      'q_values_count': snapshot.qValues.length,
      'confidence_percent': (snapshot.confidenceScore * 100).round(),
      'uncertainty_percent': (snapshot.uncertaintyScore * 100).round(),
    };
  }

  List<InspectionRuntimeAlertItem> _buildLocalRuntimeAlerts(
    InspectionRuntimeSnapshot snapshot,
  ) {
    final now = DateTime.now();
    final alerts = <InspectionRuntimeAlertItem>[];

    final uncertaintyPercent = (snapshot.uncertaintyScore * 100).round();
    if (uncertaintyPercent >= 55) {
      alerts.add(
        InspectionRuntimeAlertItem(
          name: 'local_uncertainty_warning',
          metric: 'uncertainty_percent',
          value: uncertaintyPercent,
          threshold: 55,
          severity: 'warning',
          message:
              'Uncertainty is elevated. Consider adding one simpler intermediate step.',
          observedAt: now,
        ),
      );
    }

    final confidencePercent = (snapshot.confidenceScore * 100).round();
    if (confidencePercent <= 35) {
      alerts.add(
        InspectionRuntimeAlertItem(
          name: 'local_confidence_low',
          metric: 'confidence_percent',
          value: confidencePercent,
          threshold: 35,
          severity: 'warning',
          message:
              'Confidence appears low. Consider shorter feedback loops and review checkpoints.',
          observedAt: now,
        ),
      );
    }

    if (snapshot.decisionLogs.isEmpty) {
      alerts.add(
        InspectionRuntimeAlertItem(
          name: 'local_no_decision_logs',
          metric: 'decision_logs_count',
          value: 0,
          threshold: 1,
          severity: 'info',
          message:
              'No decision logs recorded yet. Runtime trace will appear after interactions.',
          observedAt: now,
        ),
      );
    }

    return alerts;
  }

  String _toRuntimeErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'Runtime backend is unavailable. Showing local fallback data.';
    }

    if (raw.length > 140) {
      return 'Runtime backend is unavailable. Showing local fallback data.';
    }

    return 'Runtime backend is unavailable. Showing local fallback data. ($raw)';
  }

  void _syncFromRuntime(InspectionRuntimeSnapshot snapshot) {
    _lastRuntimeSnapshot = snapshot;
    final shouldUseFallback = !state.runtimeFromServer;

    emit(
      state.copyWith(
        beliefs: snapshot.beliefs
            .map(
              (item) => InspectionBelief(topic: item.topic, ratio: item.ratio),
            )
            .toList(growable: false),
        planSteps: snapshot.planSteps,
        mentalStateLabel: snapshot.mentalStateLabel,
        mentalStateHint: snapshot.mentalStateHint,
        confidenceScore: snapshot.confidenceScore,
        uncertaintyScore: snapshot.uncertaintyScore,
        qValues: snapshot.qValues,
        decisionLogs: snapshot.decisionLogs
            .map(
              (item) => InspectionDecisionLog(
                action: item.action,
                reason: item.reason,
                source: item.source,
                createdAt: item.createdAt,
                uncertaintyScore: item.uncertaintyScore,
              ),
            )
            .toList(growable: false),
        updatedAt: snapshot.updatedAt,
        runtimeMetrics: shouldUseFallback
            ? _buildLocalRuntimeMetrics(snapshot)
            : state.runtimeMetrics,
        runtimeAlerts: shouldUseFallback
            ? _buildLocalRuntimeAlerts(snapshot)
            : state.runtimeAlerts,
        runtimeUpdatedAt: shouldUseFallback
            ? snapshot.updatedAt
            : state.runtimeUpdatedAt,
      ),
    );
  }

  @override
  Future<void> close() async {
    _runtimePollingTimer?.cancel();
    await _runtimeSubscription?.cancel();
    return super.close();
  }
}
