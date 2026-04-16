import '../../data/models/agentic_models.dart';

/// Interface for the `/api/v1/academic` endpoint group.
///
/// Mirrors the Session API (`/sessions`) 1:1, but uses the `/academic`
/// route prefix. The backend may use this for exam-prep or
/// academic-specific flows.
abstract interface class AcademicApiService {
  /// POST /api/v1/academic
  Future<AgenticSessionResponse> createAcademicSession({
    required String subject,
    required String topic,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? onboardingResults,
  });

  /// PATCH /api/v1/academic/{sessionId}
  Future<SessionUpdateResponse> updateAcademicSession({
    required String sessionId,
    required String status,
  });

  /// GET /api/v1/academic/pending
  Future<Map<String, dynamic>> getAcademicPending();

  /// POST /api/v1/academic/{sessionId}/interact
  Future<AgenticInteractionResponse> academicInteract({
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
}
