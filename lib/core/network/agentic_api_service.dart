import '../../data/models/agentic_models.dart';

/// Interface for the agentic backend API.
///
/// Maps 1:1 to the actual FastAPI endpoints in growmate_backend:
///   - Session management (create, update)
///   - Orchestrator interaction (interact, step)
///   - Inspection dashboard (beliefs, particles, q-values, audit logs)
///
/// Unlike [ApiService] which follows the API contract spec,
/// this interface follows the actual backend implementation where
/// a single interaction endpoint runs the full agent pipeline.
abstract interface class AgenticApiService {
  // ─── Session ───────────────────────────────────────────────────────────

  /// POST /api/v1/sessions
  /// Creates a new learning session with the orchestrator.
  Future<AgenticSessionResponse> createSession({
    required String subject,
    required String topic,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? onboardingResults,
  });

  /// PATCH /api/v1/sessions/{sessionId}
  /// Updates session status (active, completed, abandoned).
  Future<SessionUpdateResponse> updateSession({
    required String sessionId,
    required String status,
  });

  // ─── Interaction ───────────────────────────────────────────────────────

  /// POST /api/v1/sessions/{sessionId}/interact
  /// Runs one step of the agentic pipeline (Academic → Empathy → Strategy → Orchestrator).
  /// Returns a simplified [AgenticInteractionResponse].
  Future<AgenticInteractionResponse> interact({
    required String sessionId,
    required String actionType,
    String? quizId,
    Map<String, dynamic>? responseData,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? xpData,
    Map<String, dynamic>? onboardingResults,
    Map<String, dynamic>? analyticsData,
    bool isOffTopic = false,
    bool resume = false,
  });

  /// POST /api/v1/orchestrator/step
  /// Runs the full orchestrator step and returns complete state
  /// including data-driven diagnosis, interventions, and dashboard payload.
  Future<OrchestratorStepResponse> orchestratorStep({
    required String sessionId,
    String? questionId,
    Map<String, dynamic>? response,
    Map<String, dynamic>? behaviorSignals,
    Map<String, dynamic>? xpData,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? onboardingResults,
    Map<String, dynamic>? analyticsData,
    bool isOffTopic = false,
    bool resume = false,
  });

  // ─── Inspection ────────────────────────────────────────────────────────

  /// GET /api/v1/inspection/belief-state/{sessionId}
  Future<InspectionBeliefResponse> getBeliefState({required String sessionId});

  /// GET /api/v1/inspection/particle-state/{sessionId}
  Future<InspectionParticleResponse> getParticleState({
    required String sessionId,
  });

  /// GET /api/v1/inspection/q-values
  Future<InspectionQValuesResponse> getQValues();

  /// GET /api/v1/inspection/audit-logs/{sessionId}
  Future<InspectionAuditLogsResponse> getAuditLogs({required String sessionId});
}
