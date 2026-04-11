import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/inspection_runtime_store.dart';

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
  ];
}

class InspectionCubit extends Cubit<InspectionState> {
  InspectionCubit({
    FlutterSecureStorage? secureStorage,
    InspectionRuntimeStore? runtimeStore,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _runtimeStore = runtimeStore ?? InspectionRuntimeStore.instance,
       super(InspectionState.initial()) {
    unawaited(loadDevMode());

    _runtimeSubscription = _runtimeStore.stream.listen(_syncFromRuntime);
    _syncFromRuntime(_runtimeStore.snapshot);
  }

  static const String _devModeKey = 'inspection_dev_mode_enabled_v1';

  final FlutterSecureStorage _secureStorage;
  final InspectionRuntimeStore _runtimeStore;

  StreamSubscription<InspectionRuntimeSnapshot>? _runtimeSubscription;

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
    refreshNow();
  }

  void stopLiveSync() {
    if (!state.isStreaming) {
      return;
    }

    emit(state.copyWith(isStreaming: false));
  }

  void refreshNow() {
    _syncFromRuntime(_runtimeStore.snapshot);
  }

  void _syncFromRuntime(InspectionRuntimeSnapshot snapshot) {
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
      ),
    );
  }

  @override
  Future<void> close() async {
    await _runtimeSubscription?.cancel();
    return super.close();
  }
}
