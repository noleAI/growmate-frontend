import 'package:equatable/equatable.dart';

import '../../../../data/models/agentic_models.dart';

/// The possible phases of an agentic learning session.
enum AgenticPhase {
  /// No session active. Show topic selection.
  idle,

  /// Session started, waiting for first interaction.
  ready,

  /// Quiz/interaction in progress.
  interacting,

  /// Orchestrator processing (loading state).
  processing,

  /// Waiting for HITL (Human-in-the-Loop) approval.
  hitlPending,

  /// Recovery mode (de-stress, break).
  recovery,

  /// Session completed.
  completed,

  /// Error occurred.
  error,
}

class AgenticSessionState extends Equatable {
  const AgenticSessionState({
    required this.phase,
    this.sessionId,
    this.subject,
    this.topic,
    this.lastInteraction,
    this.lastOrchestratorStep,
    this.latestDashboard,
    this.currentAction,
    this.currentContent,
    this.beliefEntropy,
    this.planRepaired,
    this.errorMessage,
    this.stepCount = 0,
  });

  final AgenticPhase phase;
  final String? sessionId;
  final String? subject;
  final String? topic;

  /// Last simplified interaction response.
  final AgenticInteractionResponse? lastInteraction;

  /// Last full orchestrator step response (with data-driven payload).
  final OrchestratorStepResponse? lastOrchestratorStep;

  /// Most recent dashboard update (from WebSocket or REST).
  final DashboardUpdate? latestDashboard;

  /// Current action recommended by the orchestrator.
  final String? currentAction;

  /// Current content (hint text, explanation, etc.)
  final String? currentContent;

  /// Current belief entropy from the Bayesian tracker.
  final double? beliefEntropy;

  /// Whether the HTN plan was repaired in the last step.
  final bool? planRepaired;

  /// Error message if phase == error.
  final String? errorMessage;

  /// Number of interaction steps in this session.
  final int stepCount;

  // ─── Derived Getters ───────────────────────────────────────────────────

  bool get isLoading => phase == AgenticPhase.processing;
  bool get isActive =>
      phase == AgenticPhase.ready ||
      phase == AgenticPhase.interacting ||
      phase == AgenticPhase.processing;
  bool get isHitlPending => phase == AgenticPhase.hitlPending;
  bool get isRecovery => phase == AgenticPhase.recovery;
  bool get hasError => phase == AgenticPhase.error;

  /// Data-driven diagnosis from the last orchestrator step.
  DataDrivenPayload? get dataDriven =>
      lastOrchestratorStep?.dataDriven ??
      lastOrchestratorStep?.payload.dataDriven;

  /// Academic state from latest dashboard.
  AcademicState? get academicState => latestDashboard?.academic;

  /// Empathy state from latest dashboard.
  EmpathyState? get empathyState => latestDashboard?.empathy;

  /// Strategy state from latest dashboard.
  StrategyState? get strategyState => latestDashboard?.strategy;

  /// Orchestrator decision from latest dashboard.
  OrchestratorDecision? get orchestratorDecision =>
      latestDashboard?.orchestrator?.decision;

  factory AgenticSessionState.initial() {
    return const AgenticSessionState(phase: AgenticPhase.idle);
  }

  AgenticSessionState copyWith({
    AgenticPhase? phase,
    String? sessionId,
    String? subject,
    String? topic,
    AgenticInteractionResponse? lastInteraction,
    OrchestratorStepResponse? lastOrchestratorStep,
    DashboardUpdate? latestDashboard,
    String? currentAction,
    String? currentContent,
    double? beliefEntropy,
    bool? planRepaired,
    String? errorMessage,
    int? stepCount,
  }) {
    return AgenticSessionState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      lastOrchestratorStep: lastOrchestratorStep ?? this.lastOrchestratorStep,
      latestDashboard: latestDashboard ?? this.latestDashboard,
      currentAction: currentAction ?? this.currentAction,
      currentContent: currentContent ?? this.currentContent,
      beliefEntropy: beliefEntropy ?? this.beliefEntropy,
      planRepaired: planRepaired ?? this.planRepaired,
      errorMessage: errorMessage ?? this.errorMessage,
      stepCount: stepCount ?? this.stepCount,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    sessionId,
    subject,
    topic,
    lastInteraction,
    lastOrchestratorStep,
    latestDashboard,
    currentAction,
    currentContent,
    beliefEntropy,
    planRepaired,
    errorMessage,
    stepCount,
  ];
}
