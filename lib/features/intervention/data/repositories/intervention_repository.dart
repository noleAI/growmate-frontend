import '../../../../core/network/api_service.dart';
import '../../../../core/network/agentic_api_service.dart';
import '../../../../data/models/api_models.dart';

class InterventionRepository {
  InterventionRepository({
    ApiService? apiService,
    AgenticApiService? agenticApiService,
    required this.sessionId,
  }) : _apiService = apiService,
       _agenticApiService = agenticApiService;

  final ApiService? _apiService;
  final AgenticApiService? _agenticApiService;
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
    final agenticApiService = _agenticApiService;
    if (agenticApiService != null) {
      final response = await agenticApiService.interact(
        sessionId: sessionId,
        actionType: 'feedback',
        responseData: <String, dynamic>{
          'submission_id': submissionId,
          'diagnosis_id': diagnosisId,
          'option_id': optionId,
          'option_label': optionLabel,
          'mode': mode,
          'remaining_rest_seconds': remainingRestSeconds,
          'skipped': skipped,
        },
      );

      return InterventionFeedbackResponse.fromJson(<String, dynamic>{
        'updated_q_values': <String, dynamic>{},
        'selected_option': <String, dynamic>{
          'id': optionId,
          'label': optionLabel,
        },
        'completion': <String, dynamic>{
          'topic': optionLabel,
          'next_action': response.content,
        },
      });
    }

    final apiService = _apiService;
    if (apiService == null) {
      throw StateError('InterventionRepository requires an API service.');
    }

    final response = await apiService.submitInterventionFeedback(
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
