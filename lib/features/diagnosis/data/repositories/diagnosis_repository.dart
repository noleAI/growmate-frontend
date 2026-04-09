import '../../../../core/network/api_service.dart';

class DiagnosisRepository {
  DiagnosisRepository({required ApiService apiService, required this.sessionId})
    : _apiService = apiService;

  final ApiService _apiService;
  final String sessionId;

  Future<Map<String, dynamic>> getDiagnosis({required String answerId}) {
    return _apiService.getDiagnosis(sessionId: sessionId, answerId: answerId);
  }

  Future<Map<String, dynamic>> confirmHITL({
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  }) {
    return _apiService.confirmHITL(
      sessionId: sessionId,
      diagnosisId: diagnosisId,
      approved: approved,
      reviewerNote: reviewerNote,
    );
  }

  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    return _apiService.saveInteractionFeedback(
      sessionId: sessionId,
      submissionId: submissionId,
      diagnosisId: diagnosisId,
      eventName: eventName,
      memoryScope: memoryScope,
      reason: reason,
      metadata: metadata,
    );
  }
}
