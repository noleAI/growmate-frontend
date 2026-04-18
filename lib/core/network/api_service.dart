/// Legacy API service interface — endpoints referenced here do NOT exist
/// in the current backend.
///
/// **Migration guide:**
/// - `submitAnswer()` → use [QuizApiRepository.submitAnswer] (`POST /quiz/submit`)
/// - `submitBatchAnswers()` → iterate [QuizApiRepository.submitAnswer] per question
/// - `getDiagnosis()` / `confirmHITL()` → use [AgenticApiService.interact]
///   (`POST /sessions/{id}/interact`)
/// - `submitSignals()` → use WebSocket (`/ws/v1/behavior`)
/// - `submitInterventionFeedback()` / `saveInteractionFeedback()`
///   → use [AgenticApiService.interact] with appropriate `action_type`
@Deprecated(
  'Use QuizApiRepository for quiz flow, AgenticApiService for agentic flow. '
  'See migration guide in doc comment above.',
)
abstract interface class ApiService {
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  });

  Future<Map<String, dynamic>> getDiagnosis({
    required String sessionId,
    required String answerId,
  });

  Future<Map<String, dynamic>> submitSignals({
    required String sessionId,
    required List<Map<String, dynamic>> signals,
  });

  Future<Map<String, dynamic>> submitInterventionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String optionId,
    required String optionLabel,
    required String mode,
    required int remainingRestSeconds,
    bool skipped = false,
  });

  // ignore: non_constant_identifier_names
  Future<Map<String, dynamic>> confirmHITL({
    required String sessionId,
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  });

  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  });

  Future<Map<String, dynamic>> submitBatchAnswers({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  });
}
