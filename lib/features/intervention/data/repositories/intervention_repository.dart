import '../../../../core/network/api_service.dart';
import '../../../../data/models/api_models.dart';

class InterventionRepository {
  InterventionRepository({
    required ApiService apiService,
    required this.sessionId,
  }) : _apiService = apiService;

  final ApiService _apiService;
  final String sessionId;

  Future<InterventionFeedbackResponse> submitFeedback({
    required String submissionId,
    required String diagnosisId,
    required String optionId,
    required String optionLabel,
    required String mode,
    required int remainingRestSeconds,
    bool skipped = false,
  }) async {
    final response = await _apiService.submitInterventionFeedback(
      sessionId: sessionId,
      submissionId: submissionId,
      diagnosisId: diagnosisId,
      optionId: optionId,
      optionLabel: optionLabel,
      mode: mode,
      remainingRestSeconds: remainingRestSeconds,
      skipped: skipped,
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    return InterventionFeedbackResponse.fromJson(data);
  }
}
