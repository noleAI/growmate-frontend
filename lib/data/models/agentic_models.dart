// Dart models matching the actual GrowMate agentic backend responses.
//
// These models map directly to the FastAPI backend at:
//   - POST /api/v1/sessions
//   - POST /api/v1/sessions/{id}/interact
//   - POST /api/v1/orchestrator/step
//   - GET  /api/v1/inspection/*

// ─────────────────────────────────────────────────────────────────────────────
// Session
// ─────────────────────────────────────────────────────────────────────────────

class AgenticSessionResponse {
  const AgenticSessionResponse({
    required this.sessionId,
    required this.status,
    required this.startTime,
    required this.initialState,
  });

  final String sessionId;
  final String status;
  final String startTime;
  final Map<String, dynamic> initialState;

  factory AgenticSessionResponse.fromJson(Map<String, dynamic> json) {
    return AgenticSessionResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      initialState: _asMap(json['initial_state']),
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'status': status,
    'start_time': startTime,
    'initial_state': initialState,
  };
}

class SessionUpdateResponse {
  const SessionUpdateResponse({
    required this.status,
    required this.sessionId,
    required this.sessionStatus,
  });

  final String status;
  final String sessionId;
  final String sessionStatus;

  factory SessionUpdateResponse.fromJson(Map<String, dynamic> json) {
    return SessionUpdateResponse(
      status: (json['status'] ?? '').toString(),
      sessionId: (json['session_id'] ?? '').toString(),
      sessionStatus: (json['session_status'] ?? '').toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interaction (simplified response from POST /sessions/{id}/interact)
// ─────────────────────────────────────────────────────────────────────────────

class AgenticInteractionResponse {
  const AgenticInteractionResponse({
    required this.nextNodeType,
    required this.content,
    required this.planRepaired,
    required this.beliefEntropy,
  });

  final String nextNodeType;
  final String content;
  final bool planRepaired;
  final double beliefEntropy;

  factory AgenticInteractionResponse.fromJson(Map<String, dynamic> json) {
    return AgenticInteractionResponse(
      nextNodeType: (json['next_node_type'] ?? 'hint').toString(),
      content: (json['content'] ?? '').toString(),
      planRepaired: json['plan_repaired'] == true,
      beliefEntropy: _asDouble(json['belief_entropy']),
    );
  }

  bool get isHitlPending => nextNodeType == 'hitl_pending';
  bool get isRecovery =>
      nextNodeType == 'de_stress' || nextNodeType == 'recovery';
  bool get isBacktrackRepair => nextNodeType == 'backtrack_repair';
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Orchestrator Step (from POST /orchestrator/step)
// ─────────────────────────────────────────────────────────────────────────────

class OrchestratorStepResponse {
  const OrchestratorStepResponse({
    required this.action,
    required this.payload,
    required this.dataDriven,
    required this.dashboardUpdate,
    required this.latencyMs,
    this.reasoningMode = 'adaptive',
    this.reasoningTrace = const [],
    this.reasoningContent,
    this.reasoningConfidence,
    this.knowledgeChunks = const [],
    this.reflection,
  });

  final String action;
  final ActionPayload payload;
  final DataDrivenPayload? dataDriven;
  final DashboardUpdate dashboardUpdate;
  final int latencyMs;

  // Agentic AI fields (backward compatible — all optional with defaults)
  final String reasoningMode; // 'agentic' | 'adaptive'
  final List<ReasoningStep> reasoningTrace;
  final String? reasoningContent;
  final double? reasoningConfidence;
  final List<KnowledgeChunk> knowledgeChunks;
  final ReflectionResult? reflection;

  factory OrchestratorStepResponse.fromJson(Map<String, dynamic> json) {
    // The /orchestrator/step wraps in {"status": "ok", "result": {...}}
    final result = _asMap(json['result'] ?? json);

    return OrchestratorStepResponse(
      action: (result['action'] ?? 'hint').toString(),
      payload: ActionPayload.fromJson(_asMap(result['payload'])),
      dataDriven: result['data_driven'] != null
          ? DataDrivenPayload.fromJson(_asMap(result['data_driven']))
          : null,
      dashboardUpdate: DashboardUpdate.fromJson(
        _asMap(result['dashboard_update']),
      ),
      latencyMs: _asInt(result['latency_ms']),
      // Agentic fields (fallback for backward compat with old backend)
      reasoningMode: (result['reasoning_mode'] ?? 'adaptive').toString(),
      reasoningTrace:
          (result['reasoning_trace'] as List<dynamic>?)
              ?.map((e) => ReasoningStep.fromJson(_asMap(e)))
              .toList() ??
          const [],
      reasoningContent: result['reasoning_content']?.toString(),
      reasoningConfidence: result['reasoning_confidence'] != null
          ? _asDouble(result['reasoning_confidence'])
          : null,
      knowledgeChunks:
          (result['knowledge_chunks'] as List<dynamic>?)
              ?.map((e) => KnowledgeChunk.fromJson(_asMap(e)))
              .toList() ??
          const [],
      reflection: result['reflection'] != null
          ? ReflectionResult.fromJson(_asMap(result['reflection']))
          : null,
    );
  }

  bool get isHitlPending => action == 'hitl_pending' || action == 'hitl';
  bool get isRecovery => action == 'de_stress' || action == 'recovery';
  bool get isAgenticMode => reasoningMode == 'agentic';
  bool get hasReasoningTrace => reasoningTrace.isNotEmpty;
  bool get hasKnowledge => knowledgeChunks.isNotEmpty;
  bool get hasReflection => reflection != null;
}

class ActionPayload {
  const ActionPayload({
    required this.text,
    required this.fallbackUsed,
    this.dataDriven,
  });

  final String text;
  final bool fallbackUsed;
  final DataDrivenPayload? dataDriven;

  factory ActionPayload.fromJson(Map<String, dynamic> json) {
    return ActionPayload(
      text: (json['text'] ?? '').toString(),
      fallbackUsed: json['fallback_used'] == true,
      dataDriven: json['data_driven'] != null
          ? DataDrivenPayload.fromJson(_asMap(json['data_driven']))
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data-Driven Payload (diagnosis + interventions from Package 2/3/4)
// ─────────────────────────────────────────────────────────────────────────────

class DataDrivenPayload {
  const DataDrivenPayload({
    required this.diagnosis,
    required this.interventions,
    required this.selectedIntervention,
    required this.systemBehavior,
    this.formulaRecommendations = const [],
  });

  final Map<String, dynamic>? diagnosis;
  final List<Map<String, dynamic>> interventions;
  final Map<String, dynamic>? selectedIntervention;
  final SystemBehavior systemBehavior;

  /// Formula recommendations from the data-driven pipeline.
  final List<Map<String, dynamic>> formulaRecommendations;

  factory DataDrivenPayload.fromJson(Map<String, dynamic> json) {
    final rawInterventions = json['interventions'];
    final interventionsList = <Map<String, dynamic>>[];
    if (rawInterventions is List) {
      for (final item in rawInterventions) {
        if (item is Map) {
          interventionsList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final rawFormulas = json['formulaRecommendations'];
    final formulasList = <Map<String, dynamic>>[];
    if (rawFormulas is List) {
      for (final item in rawFormulas) {
        if (item is Map) {
          formulasList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return DataDrivenPayload(
      diagnosis: json['diagnosis'] is Map
          ? Map<String, dynamic>.from(json['diagnosis'] as Map)
          : null,
      interventions: interventionsList,
      selectedIntervention: json['selectedIntervention'] is Map
          ? Map<String, dynamic>.from(json['selectedIntervention'] as Map)
          : null,
      systemBehavior: SystemBehavior.fromJson(_asMap(json['systemBehavior'])),
      formulaRecommendations: formulasList,
    );
  }

  String get mode => systemBehavior.finalMode;
  bool get requiresHitl => systemBehavior.requiresHITL;
  String get riskBand => systemBehavior.riskBand;
}

class SystemBehavior {
  const SystemBehavior({
    required this.riskBand,
    required this.confidenceBand,
    required this.hitlTriggered,
    required this.fallbackRuleApplied,
    required this.finalMode,
    required this.requiresHITL,
  });

  final String riskBand;
  final String confidenceBand;
  final bool hitlTriggered;
  final String? fallbackRuleApplied;
  final String finalMode;
  final bool requiresHITL;

  factory SystemBehavior.fromJson(Map<String, dynamic> json) {
    return SystemBehavior(
      riskBand: (json['riskBandFromThresholds'] ?? 'medium').toString(),
      confidenceBand: (json['confidenceBandFromThresholds'] ?? 'medium')
          .toString(),
      hitlTriggered: json['hitlTriggered'] == true,
      fallbackRuleApplied: json['fallbackRuleApplied']?.toString(),
      finalMode: (json['finalMode'] ?? 'normal').toString(),
      requiresHITL: json['requiresHITL'] == true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Update (WebSocket broadcast payload)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardUpdate {
  const DashboardUpdate({
    required this.sessionId,
    required this.step,
    required this.action,
    required this.actionPayload,
    required this.hitlPending,
    required this.academic,
    required this.empathy,
    required this.strategy,
    required this.orchestrator,
    this.dataDriven,
  });

  final String sessionId;
  final int step;
  final String action;
  final Map<String, dynamic> actionPayload;
  final bool hitlPending;
  final AcademicState academic;
  final EmpathyState empathy;
  final StrategyState strategy;
  final OrchestratorState? orchestrator;
  final DataDrivenPayload? dataDriven;

  factory DashboardUpdate.fromJson(Map<String, dynamic> json) {
    return DashboardUpdate(
      sessionId: (json['session_id'] ?? '').toString(),
      step: _asInt(json['step']),
      action: (json['action'] ?? '').toString(),
      actionPayload: _asMap(json['action_payload']),
      hitlPending: json['hitl_pending'] == true,
      academic: AcademicState.fromJson(_asMap(json['academic'])),
      empathy: EmpathyState.fromJson(_asMap(json['empathy'])),
      strategy: StrategyState.fromJson(_asMap(json['strategy'])),
      orchestrator: json['orchestrator'] != null
          ? OrchestratorState.fromJson(_asMap(json['orchestrator']))
          : null,
      dataDriven: json['data_driven'] != null
          ? DataDrivenPayload.fromJson(_asMap(json['data_driven']))
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Agent States (sub-payloads of DashboardUpdate)
// ─────────────────────────────────────────────────────────────────────────────

class AcademicState {
  const AcademicState({
    required this.beliefDistribution,
    required this.entropy,
    required this.confidence,
    required this.topHypothesis,
  });

  final Map<String, double> beliefDistribution;
  final double entropy;
  final double confidence;
  final String topHypothesis;

  factory AcademicState.fromJson(Map<String, dynamic> json) {
    final rawBeliefs = json['belief_distribution'];
    final beliefs = <String, double>{};
    if (rawBeliefs is Map) {
      for (final entry in rawBeliefs.entries) {
        beliefs[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    return AcademicState(
      beliefDistribution: beliefs,
      entropy: _asDouble(json['entropy']),
      confidence: _asDouble(json['confidence']),
      topHypothesis: (json['top_hypothesis'] ?? '').toString(),
    );
  }

  bool get isHighEntropy => entropy >= 0.75;
}

class EmpathyState {
  const EmpathyState({
    required this.confusion,
    required this.fatigue,
    required this.uncertainty,
    required this.ess,
    required this.step,
    required this.qState,
    required this.hitlTriggered,
    required this.recommendedAction,
    required this.particleDistribution,
  });

  final double confusion;
  final double fatigue;
  final double uncertainty;
  final double ess;
  final int step;
  final String qState;
  final bool hitlTriggered;
  final String recommendedAction;
  final Map<String, double> particleDistribution;

  factory EmpathyState.fromJson(Map<String, dynamic> json) {
    // Handle both direct and nested (format_pf_payload) structures
    final estimation = _asMap(json['estimation']);
    final confusion = _asDouble(estimation['confusion'] ?? json['confusion']);
    final fatigue = _asDouble(estimation['fatigue'] ?? json['fatigue']);
    final uncertainty = _asDouble(
      estimation['uncertainty'] ?? json['uncertainty'],
    );

    final rawDist =
        json['particle_distribution'] ?? json['belief_distribution'];
    final dist = <String, double>{};
    if (rawDist is Map) {
      for (final entry in rawDist.entries) {
        dist[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    return EmpathyState(
      confusion: confusion,
      fatigue: fatigue,
      uncertainty: uncertainty,
      ess: _asDouble(json['ess']),
      step: _asInt(json['step']),
      qState: (json['q_state'] ?? '').toString(),
      hitlTriggered: json['hitl_triggered'] == true,
      recommendedAction: (json['recommended_action'] ?? '').toString(),
      particleDistribution: dist,
    );
  }

  bool get isExhausted => fatigue >= 0.8;
  bool get isConfused => confusion >= 0.6;
  bool get isHighUncertainty => uncertainty >= 0.75;

  String get dominantState {
    if (isExhausted) return 'exhausted';
    if (isConfused) return 'confused';
    if (uncertainty < 0.3) return 'focused';
    return 'uncertain';
  }
}

class StrategyState {
  const StrategyState({
    required this.qValues,
    required this.qState,
    required this.avgReward,
  });

  final Map<String, double> qValues;
  final String qState;
  final double avgReward;

  factory StrategyState.fromJson(Map<String, dynamic> json) {
    final rawQValues = json['q_values'];
    final qValues = <String, double>{};
    if (rawQValues is Map) {
      for (final entry in rawQValues.entries) {
        qValues[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    return StrategyState(
      qValues: qValues,
      qState: (json['q_state'] ?? '').toString(),
      avgReward: _asDouble(json['avg_reward']),
    );
  }

  String? get bestStrategy {
    if (qValues.isEmpty) return null;
    return qValues.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class OrchestratorState {
  const OrchestratorState({required this.decision, required this.monitoring});

  final OrchestratorDecision decision;
  final Map<String, double> monitoring;

  factory OrchestratorState.fromJson(Map<String, dynamic> json) {
    final rawMonitoring = json['monitoring'];
    final monitoring = <String, double>{};
    if (rawMonitoring is Map) {
      for (final entry in rawMonitoring.entries) {
        monitoring[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    return OrchestratorState(
      decision: OrchestratorDecision.fromJson(_asMap(json['decision'])),
      monitoring: monitoring,
    );
  }
}

class OrchestratorDecision {
  const OrchestratorDecision({
    required this.action,
    required this.actionDistribution,
    required this.totalUncertainty,
    required this.hitlTriggered,
    required this.rationale,
  });

  final String action;
  final Map<String, double> actionDistribution;
  final double totalUncertainty;
  final bool hitlTriggered;
  final String rationale;

  factory OrchestratorDecision.fromJson(Map<String, dynamic> json) {
    final rawDist = json['action_distribution'];
    final dist = <String, double>{};
    if (rawDist is Map) {
      for (final entry in rawDist.entries) {
        dist[entry.key.toString()] = _asDouble(entry.value);
      }
    }

    return OrchestratorDecision(
      action: (json['action'] ?? '').toString(),
      actionDistribution: dist,
      totalUncertainty: _asDouble(json['total_uncertainty']),
      hitlTriggered: json['hitl_triggered'] == true,
      rationale: (json['rationale'] ?? '').toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspection Endpoints
// ─────────────────────────────────────────────────────────────────────────────

class InspectionBeliefResponse {
  const InspectionBeliefResponse({
    required this.sessionId,
    required this.beliefs,
  });

  final String sessionId;
  final Map<String, double> beliefs;

  factory InspectionBeliefResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['beliefs'];
    final beliefs = <String, double>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        beliefs[entry.key.toString()] = _asDouble(entry.value);
      }
    }
    return InspectionBeliefResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      beliefs: beliefs,
    );
  }
}

class InspectionParticleResponse {
  const InspectionParticleResponse({
    required this.sessionId,
    required this.stateSummary,
  });

  final String sessionId;
  final Map<String, dynamic> stateSummary;

  factory InspectionParticleResponse.fromJson(Map<String, dynamic> json) {
    return InspectionParticleResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      stateSummary: _asMap(json['state_summary']),
    );
  }
}

class InspectionQValuesResponse {
  const InspectionQValuesResponse({required this.qTable});

  final Map<String, dynamic> qTable;

  factory InspectionQValuesResponse.fromJson(Map<String, dynamic> json) {
    return InspectionQValuesResponse(qTable: _asMap(json['q_table']));
  }
}

class InspectionAuditLogsResponse {
  const InspectionAuditLogsResponse({
    required this.sessionId,
    required this.logs,
  });

  final String sessionId;
  final List<Map<String, dynamic>> logs;

  factory InspectionAuditLogsResponse.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'];
    final logs = <Map<String, dynamic>>[];
    if (rawLogs is List) {
      for (final item in rawLogs) {
        if (item is Map) {
          logs.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return InspectionAuditLogsResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      logs: logs,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket Events
// ─────────────────────────────────────────────────────────────────────────────

class BehaviorWsEvent {
  const BehaviorWsEvent({
    required this.event,
    required this.sessionId,
    this.type,
    this.confidence,
    this.stateSummary,
    this.message,
  });

  final String event;
  final String sessionId;
  final String? type;
  final double? confidence;
  final Map<String, dynamic>? stateSummary;
  final String? message;

  factory BehaviorWsEvent.fromJson(Map<String, dynamic> json) {
    return BehaviorWsEvent(
      event: (json['event'] ?? '').toString(),
      sessionId: (json['session_id'] ?? '').toString(),
      type: json['type']?.toString(),
      confidence: json['confidence'] != null
          ? _asDouble(json['confidence'])
          : null,
      stateSummary: json['state_summary'] is Map
          ? Map<String, dynamic>.from(json['state_summary'] as Map)
          : null,
      message: json['message']?.toString(),
    );
  }

  bool get isInterventionProposed => event == 'intervention_proposed';
  bool get isHitlTriggered => event == 'hitl_triggered';
  bool get isInvalidPayload => event == 'invalid_payload';
}

// ─────────────────────────────────────────────────────────────────────────────
// Agentic AI Models (reasoning trace, RAG knowledge, self-reflection)
// ─────────────────────────────────────────────────────────────────────────────

/// A single step in the LLM's reasoning chain.
class ReasoningStep {
  const ReasoningStep({
    required this.step,
    required this.tool,
    this.args = const {},
    this.resultSummary = '',
  });

  final int step;
  final String tool;
  final Map<String, dynamic> args;
  final String resultSummary;

  factory ReasoningStep.fromJson(Map<String, dynamic> json) {
    return ReasoningStep(
      step: _asInt(json['step']),
      tool: (json['tool'] ?? '').toString(),
      args: _asMap(json['args']),
      resultSummary: (json['result_summary'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'tool': tool,
    'args': args,
    'result_summary': resultSummary,
  };

  /// Icon cho từng loại tool.
  String get toolIcon {
    return switch (tool) {
      'get_academic_beliefs' => '🧠',
      'get_empathy_state' => '💛',
      'get_strategy_suggestion' => '🎯',
      'search_knowledge' => '📚',
      'get_student_history' => '📊',
      'get_formula_bank' => '📐',
      'get_orchestrator_score' => '⚙️',
      _ => '🔧',
    };
  }

  /// Label tiếng Việt cho tool.
  String get toolLabel {
    return switch (tool) {
      'get_academic_beliefs' => 'Phân tích kiến thức',
      'get_empathy_state' => 'Đánh giá cảm xúc',
      'get_strategy_suggestion' => 'Gợi ý chiến lược',
      'search_knowledge' => 'Tra cứu kiến thức',
      'get_student_history' => 'Xem lịch sử',
      'get_formula_bank' => 'Tìm công thức',
      'get_orchestrator_score' => 'Tính điểm utility',
      _ => tool,
    };
  }
}

/// A knowledge chunk retrieved via RAG pipeline.
class KnowledgeChunk {
  const KnowledgeChunk({
    required this.content,
    required this.source,
    this.chapter = '',
    this.similarity = 0.0,
  });

  final String content;
  final String source;
  final String chapter;
  final double similarity;

  factory KnowledgeChunk.fromJson(Map<String, dynamic> json) {
    return KnowledgeChunk(
      content: (json['content'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      chapter: (json['chapter'] ?? '').toString(),
      similarity: _asDouble(json['similarity']),
    );
  }

  /// Label tiếng Việt cho source.
  String get sourceLabel {
    return switch (source) {
      'sgk_toan_12' => 'SGK Toán 12',
      'cong_thuc' => 'Công thức',
      'bai_giai_mau' => 'Bài giải mẫu',
      'loi_thuong_gap' => 'Lỗi thường gặp',
      _ => source,
    };
  }
}

/// AI self-reflection result.
class ReflectionResult {
  const ReflectionResult({
    required this.effectiveness,
    required this.shouldChangeStrategy,
    this.entropyTrend = 'stable',
    this.accuracyTrend = 'stable',
    this.emotionTrend = 'stable',
    this.recommendation = '',
    this.reasoning = '',
  });

  final String effectiveness;
  final bool shouldChangeStrategy;
  final String entropyTrend;
  final String accuracyTrend;
  final String emotionTrend;
  final String recommendation;
  final String reasoning;

  factory ReflectionResult.fromJson(Map<String, dynamic> json) {
    return ReflectionResult(
      effectiveness: (json['effectiveness'] ?? 'neutral').toString(),
      shouldChangeStrategy: json['should_change_strategy'] == true,
      entropyTrend: (json['entropy_trend'] ?? 'stable').toString(),
      accuracyTrend: (json['accuracy_trend'] ?? 'stable').toString(),
      emotionTrend: (json['emotion_trend'] ?? 'stable').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      reasoning: (json['reasoning'] ?? '').toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
