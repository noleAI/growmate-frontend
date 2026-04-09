import 'dart:async';

class InspectionRuntimeBelief {
  const InspectionRuntimeBelief({required this.topic, required this.ratio});

  final String topic;
  final double ratio;
}

class InspectionRuntimeDecision {
  const InspectionRuntimeDecision({
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
}

class InspectionRuntimeSnapshot {
  const InspectionRuntimeSnapshot({
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

  final List<InspectionRuntimeBelief> beliefs;
  final List<String> planSteps;
  final String mentalStateLabel;
  final String mentalStateHint;
  final double confidenceScore;
  final double uncertaintyScore;
  final Map<String, double> qValues;
  final List<InspectionRuntimeDecision> decisionLogs;
  final DateTime updatedAt;

  factory InspectionRuntimeSnapshot.initial() {
    return InspectionRuntimeSnapshot(
      beliefs: const <InspectionRuntimeBelief>[
        InspectionRuntimeBelief(topic: 'Đạo hàm', ratio: 0.85),
        InspectionRuntimeBelief(topic: 'Tích phân', ratio: 0.15),
      ],
      planSteps: const <String>[
        'Step 1: Diagnose',
        'Step 2: Remedial',
        'Step 3: Review',
      ],
      mentalStateLabel: 'Tập trung',
      mentalStateHint: 'Nhịp học ổn định, có thể tăng nhẹ độ khó.',
      confidenceScore: 0.85,
      uncertaintyScore: 0.15,
      qValues: const <String, double>{},
      decisionLogs: const <InspectionRuntimeDecision>[],
      updatedAt: DateTime.now(),
    );
  }

  InspectionRuntimeSnapshot copyWith({
    List<InspectionRuntimeBelief>? beliefs,
    List<String>? planSteps,
    String? mentalStateLabel,
    String? mentalStateHint,
    double? confidenceScore,
    double? uncertaintyScore,
    Map<String, double>? qValues,
    List<InspectionRuntimeDecision>? decisionLogs,
    DateTime? updatedAt,
  }) {
    return InspectionRuntimeSnapshot(
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
}

class InspectionRuntimeStore {
  InspectionRuntimeStore._internal();

  static final InspectionRuntimeStore instance =
      InspectionRuntimeStore._internal();

  static const int _maxDecisionLogs = 24;

  final StreamController<InspectionRuntimeSnapshot> _controller =
      StreamController<InspectionRuntimeSnapshot>.broadcast();

  InspectionRuntimeSnapshot _snapshot = InspectionRuntimeSnapshot.initial();

  Stream<InspectionRuntimeSnapshot> get stream => _controller.stream;
  InspectionRuntimeSnapshot get snapshot => _snapshot;

  void syncFromDiagnosis({
    required String gapAnalysis,
    required String diagnosisReason,
    required List<String> strengths,
    required List<String> needsReview,
    required String nextSuggestedTopic,
    required String finalMode,
    required double confidenceScore,
    String? riskLevel,
  }) {
    final now = DateTime.now();
    final safeConfidence = _clamp01(confidenceScore);
    final uncertainty = _clamp01(1 - safeConfidence);

    final focusTopic = needsReview.isNotEmpty ? needsReview.first : gapAnalysis;
    final strengthTopic = strengths.isNotEmpty
        ? strengths.first
        : 'Nền tảng hiện tại';

    final rawBeliefs = <InspectionRuntimeBelief>[
      InspectionRuntimeBelief(
        topic: focusTopic,
        ratio: 0.35 + (uncertainty * 0.45),
      ),
      InspectionRuntimeBelief(
        topic: strengthTopic,
        ratio: 0.65 - (uncertainty * 0.25),
      ),
    ];

    final normalizedRisk = (riskLevel ?? '').toLowerCase();
    if (finalMode == 'recovery' || normalizedRisk == 'high') {
      rawBeliefs.add(
        InspectionRuntimeBelief(
          topic: 'Mức áp lực',
          ratio: 0.20 + (uncertainty * 0.30),
        ),
      );
    }

    final beliefs = _normalizeBeliefs(rawBeliefs);
    final planSteps = <String>[
      'Step 1: Diagnose nhẹ cho $focusTopic',
      'Step 2: Remedial theo hướng $nextSuggestedTopic',
      'Step 3: Review ngắn để củng cố tự tin',
    ];

    final mentalState = _mentalStateBySignal(
      finalMode: finalMode,
      uncertainty: uncertainty,
      normalizedRisk: normalizedRisk,
    );

    final nextDecisionLogs = <InspectionRuntimeDecision>[
      InspectionRuntimeDecision(
        action: 'Diagnosis Updated',
        reason: diagnosisReason,
        source: 'diagnosis',
        createdAt: now,
        uncertaintyScore: uncertainty,
      ),
      ..._snapshot.decisionLogs,
    ].take(_maxDecisionLogs).toList(growable: false);

    _emit(
      _snapshot.copyWith(
        beliefs: beliefs,
        planSteps: planSteps,
        mentalStateLabel: mentalState.$1,
        mentalStateHint: mentalState.$2,
        confidenceScore: safeConfidence,
        uncertaintyScore: uncertainty,
        decisionLogs: nextDecisionLogs,
        updatedAt: now,
      ),
    );
  }

  void updateQValues(Map<String, dynamic> incoming) {
    final parsed = <String, double>{};

    for (final entry in incoming.entries) {
      final score = _toDouble(entry.value);
      if (score == null) {
        continue;
      }
      parsed[entry.key] = score;
    }

    if (parsed.isEmpty) {
      return;
    }

    final merged = Map<String, double>.from(_snapshot.qValues)..addAll(parsed);

    _emit(_snapshot.copyWith(qValues: merged, updatedAt: DateTime.now()));
  }

  void addDecision({
    required String action,
    required String reason,
    required String source,
    double? uncertaintyScore,
  }) {
    final nextDecisionLogs = <InspectionRuntimeDecision>[
      InspectionRuntimeDecision(
        action: action,
        reason: reason,
        source: source,
        createdAt: DateTime.now(),
        uncertaintyScore: uncertaintyScore,
      ),
      ..._snapshot.decisionLogs,
    ].take(_maxDecisionLogs).toList(growable: false);

    _emit(
      _snapshot.copyWith(
        decisionLogs: nextDecisionLogs,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updateMentalState({required String label, required String hint}) {
    _emit(
      _snapshot.copyWith(
        mentalStateLabel: label,
        mentalStateHint: hint,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void clear() {
    _emit(InspectionRuntimeSnapshot.initial());
  }

  void _emit(InspectionRuntimeSnapshot next) {
    _snapshot = next;
    if (!_controller.isClosed) {
      _controller.add(_snapshot);
    }
  }

  static List<InspectionRuntimeBelief> _normalizeBeliefs(
    List<InspectionRuntimeBelief> raw,
  ) {
    final cleaned = raw
        .map(
          (item) => InspectionRuntimeBelief(
            topic: item.topic,
            ratio: _clamp01(item.ratio),
          ),
        )
        .toList(growable: false);

    final total = cleaned.fold<double>(0, (sum, item) => sum + item.ratio);

    if (total <= 0) {
      return const <InspectionRuntimeBelief>[
        InspectionRuntimeBelief(topic: 'Đạo hàm', ratio: 0.5),
        InspectionRuntimeBelief(topic: 'Tích phân', ratio: 0.5),
      ];
    }

    return cleaned
        .map(
          (item) => InspectionRuntimeBelief(
            topic: item.topic,
            ratio: item.ratio / total,
          ),
        )
        .toList(growable: false);
  }

  static (String, String) _mentalStateBySignal({
    required String finalMode,
    required double uncertainty,
    required String normalizedRisk,
  }) {
    if (finalMode == 'recovery' || normalizedRisk == 'high') {
      return (
        'Hơi mệt',
        'Hệ thống ưu tiên nhịp học phục hồi để giảm tải nhận thức.',
      );
    }

    if (uncertainty >= 0.45) {
      return (
        'Bối rối nhẹ',
        'Độ bất định cao, nên thêm gợi ý từng bước để giữ nhịp học.',
      );
    }

    return (
      'Tập trung',
      'Năng lượng ổn định, có thể tiếp tục nhịp học hiện tại.',
    );
  }

  static double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
