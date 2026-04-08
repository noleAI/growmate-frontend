import '../../../../core/network/api_service.dart';

class InterventionRepository {
  InterventionRepository({required ApiService apiService, required this.sessionId})
      : _apiService = apiService;

  final ApiService _apiService;
  final String sessionId;

  Future<Map<String, dynamic>> submitFeedback({
    required String submissionId,
    required String diagnosisId,
    required String optionId,
    required String optionLabel,
    required String mode,
    required int remainingRestSeconds,
    bool skipped = false,
  }) {
    return _apiService.submitInterventionFeedback(
      sessionId: sessionId,
      submissionId: submissionId,
      diagnosisId: diagnosisId,
      optionId: optionId,
      optionLabel: optionLabel,
      mode: mode,
      remainingRestSeconds: remainingRestSeconds,
      skipped: skipped,
    );
  }
}
