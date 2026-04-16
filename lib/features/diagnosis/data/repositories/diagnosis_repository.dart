import '../../../../core/network/api_service.dart';
import '../../../../data/models/api_models.dart';

/// Abstract interface for diagnosis repositories.
abstract class DiagnosisRepository {
  Future<DiagnosisResponse> getDiagnosis({required String answerId});

  Future<Map<String, dynamic>> confirmHITL({
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  });

  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  });
}

/// Default implementation backed by [ApiService] (mock or Supabase RPC).
class MockDiagnosisRepository implements DiagnosisRepository {
  MockDiagnosisRepository({
    required ApiService apiService,
    required this.sessionId,
  }) : _apiService = apiService;

  final ApiService _apiService;
  final String sessionId;

  @override
  Future<DiagnosisResponse> getDiagnosis({required String answerId}) async {
    final response = await _apiService.getDiagnosis(
      sessionId: sessionId,
      answerId: answerId,
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    return DiagnosisResponse.fromJson(data);
  }

  @override
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

  @override
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
