import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/agentic_api_service.dart';
import '../../../../core/network/ws_service.dart';
import '../../../../data/models/agentic_models.dart';

/// Repository that orchestrates all communication with the agentic backend.
///
/// This is the single entry point for the UI layer. It:
///   1. Manages session lifecycle (create → interact → complete)
///   2. Sends quiz answers through the orchestrator pipeline
///   3. Streams real-time dashboard updates via WebSocket
///   4. Sends behavioral signals for Particle Filter processing
///
/// ## Data Flow
/// ```
/// UI → AgenticSessionRepository → AgenticApiService (REST)
///                                → AgenticWsService  (WebSocket)
///                                     ↓
///                         Backend Orchestrator Pipeline
///                    (Academic → Empathy → Strategy → Engine)
///                                     ↓
///                          ← InteractionResponse (REST)
///                          ← DashboardUpdate     (WS)
///                          ← BehaviorWsEvent     (WS)
/// ```
class AgenticSessionRepository {
  AgenticSessionRepository({
    required AgenticApiService apiService,
    required AgenticWsService wsService,
  }) : _api = apiService,
       _ws = wsService;

  final AgenticApiService _api;
  final AgenticWsService _ws;

  String? _sessionId;
  String? get activeSessionId => _sessionId;
  bool get hasActiveSession => _sessionId != null;

  /// Real-time dashboard updates (academic, empathy, strategy, orchestrator).
  Stream<DashboardUpdate> get dashboardUpdates => _ws.dashboardUpdates;

  /// Behavior events (intervention_proposed, hitl_triggered).
  Stream<BehaviorWsEvent> get behaviorEvents => _ws.behaviorEvents;

  // ─── Session Lifecycle ─────────────────────────────────────────────────

  /// Creates a new agentic session and opens both WebSocket channels.
  ///
  /// Returns the session response with initial state (beliefs, topic, etc.)
  Future<AgenticSessionResponse> startSession({
    required String subject,
    required String topic,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? onboardingResults,
  }) async {
    final response = await _api.createSession(
      subject: subject,
      topic: topic,
      mode: mode,
      classificationLevel: classificationLevel,
      onboardingResults: onboardingResults,
    );

    _sessionId = response.sessionId;

    // Open WebSocket connections for real-time features
    await _ws.connectAll(response.sessionId);

    _log('Session started: ${response.sessionId}');
    return response;
  }

  /// Completes or abandons the current session.
  Future<SessionUpdateResponse> endSession({
    String status = 'completed',
  }) async {
    if (_sessionId == null) {
      throw StateError('No active session to end');
    }

    final response = await _api.updateSession(
      sessionId: _sessionId!,
      status: status,
    );

    _ws.disconnectAll();
    final endedId = _sessionId;
    _sessionId = null;

    _log('Session ended ($status): $endedId');
    return response;
  }

  // ─── Interaction (Quiz Flow) ───────────────────────────────────────────

  /// Submits a quiz answer through the orchestrator pipeline.
  ///
  /// This triggers the full agentic flow:
  ///   1. Academic Agent: Updates Bayesian beliefs
  ///   2. Empathy Agent: Updates particle filter with behavior signals
  ///   3. Strategy Agent: Updates Q-values
  ///   4. Orchestrator Engine: Aggregates, decides, and returns action
  ///
  /// The simplified response contains the next action (hint, drill, etc.)
  /// and belief entropy. The full dashboard state arrives via WebSocket.
  Future<AgenticInteractionResponse> submitAnswer({
    required String questionId,
    required Map<String, dynamic> responseData,
    bool resume = false,
  }) {
    _ensureSession();
    return _api.interact(
      sessionId: _sessionId!,
      actionType: 'submit_answer',
      quizId: questionId,
      responseData: responseData,
      resume: resume,
    );
  }

  /// Sends a general interaction (e.g., feedback, navigation, skip).
  Future<AgenticInteractionResponse> sendInteraction({
    required String actionType,
    String? quizId,
    Map<String, dynamic>? responseData,
  }) {
    _ensureSession();
    return _api.interact(
      sessionId: _sessionId!,
      actionType: actionType,
      quizId: quizId,
      responseData: responseData,
    );
  }

  /// Runs a full orchestrator step with explicit control over all inputs.
  ///
  /// Returns the complete response including data-driven diagnosis,
  /// intervention plans, and full dashboard payload.
  /// Use this when you need the full agentic state (e.g., diagnosis screen).
  Future<OrchestratorStepResponse> runOrchestratorStep({
    String? questionId,
    Map<String, dynamic>? response,
    Map<String, dynamic>? behaviorSignals,
  }) {
    _ensureSession();
    return _api.orchestratorStep(
      sessionId: _sessionId!,
      questionId: questionId,
      response: response,
      behaviorSignals: behaviorSignals,
    );
  }

  // ─── Behavioral Signals (Real-time) ────────────────────────────────────

  /// Sends a behavioral signal to the Particle Filter via WebSocket.
  ///
  /// Called by the behavioral signal service when it detects:
  /// - Typing speed changes
  /// - Idle time
  /// - Correction rate
  /// - Response time
  void sendBehaviorSignal({
    required double typingSpeed,
    required double idleTime,
    required double correctionRate,
    double? responseTime,
  }) {
    final signal = <String, dynamic>{
      'typing_speed': typingSpeed,
      'idle_time': idleTime,
      'correction_rate': correctionRate,
    };
    if (responseTime != null) signal['response_time'] = responseTime;
    _ws.sendBehaviorSignal(signal);
  }

  // ─── Inspection (Dev Dashboard) ────────────────────────────────────────

  /// Fetches current Bayesian belief state.
  Future<InspectionBeliefResponse> getBeliefState() {
    _ensureSession();
    return _api.getBeliefState(sessionId: _sessionId!);
  }

  /// Fetches current Particle Filter state summary.
  Future<InspectionParticleResponse> getParticleState() {
    _ensureSession();
    return _api.getParticleState(sessionId: _sessionId!);
  }

  /// Fetches global Q-learning table.
  Future<InspectionQValuesResponse> getQValues() {
    return _api.getQValues();
  }

  /// Fetches audit logs for the current session.
  Future<InspectionAuditLogsResponse> getAuditLogs() {
    _ensureSession();
    return _api.getAuditLogs(sessionId: _sessionId!);
  }

  /// Reconnects real-time streams for the current session when Home refreshes.
  Future<void> ensureRealtimeConnected() async {
    if (_sessionId == null) {
      return;
    }
    if (_ws.isBehaviorConnected && _ws.isDashboardConnected) {
      return;
    }

    await _ws.connectAll(_sessionId!);
    _log('Realtime streams reconnected: $_sessionId');
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────

  void dispose() {
    _ws.dispose();
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  void _ensureSession() {
    if (_sessionId == null) {
      throw StateError('No active agentic session. Call startSession() first.');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('📘 [AgenticRepo] $message');
  }
}
