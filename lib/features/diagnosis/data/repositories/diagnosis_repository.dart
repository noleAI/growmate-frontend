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
}
