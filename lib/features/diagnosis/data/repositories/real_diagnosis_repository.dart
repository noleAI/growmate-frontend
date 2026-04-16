import '../../../../core/network/agentic_api_service.dart';
import '../../../../data/models/api_models.dart';
import 'diagnosis_repository.dart';

/// Diagnosis repository backed by the real agentic orchestrator.
///
/// Uses `POST /orchestrator/step` to drive the diagnosis pipeline
/// (Academic → Empathy → Strategy → Orchestrator) and maps the
/// [OrchestratorStepResponse] to the existing [DiagnosisResponse] model.
class RealDiagnosisRepository implements DiagnosisRepository {
  RealDiagnosisRepository({
    required AgenticApiService apiService,
    required this.sessionId,
  }) : _api = apiService;

  final AgenticApiService _api;
  final String sessionId;

  @override
  Future<DiagnosisResponse> getDiagnosis({required String answerId}) async {
    final orchestratorResponse = await _api.orchestratorStep(
      sessionId: sessionId,
      questionId: answerId,
    );

    final dd = orchestratorResponse.dataDriven;
    final diagnosis = dd?.diagnosis ?? <String, dynamic>{};
    final interventions = dd?.interventions ?? [];
    final mode = dd?.mode ?? 'normal';
    final requiresHitl = dd?.requiresHitl ?? false;

    return DiagnosisResponse(
      diagnosisId: _str(diagnosis['diagnosis_id'] ?? diagnosis['diagnosisId']),
      title: _str(diagnosis['title']),
      gapAnalysis: _str(diagnosis['gap_analysis'] ?? diagnosis['gapAnalysis']),
      summary: _str(diagnosis['summary']),
      diagnosisReason: _str(
        diagnosis['diagnosis_reason'] ?? diagnosis['diagnosisReason'],
      ),
      strengths: _strList(diagnosis['strengths']),
      needsReview: _strList(
        diagnosis['needs_review'] ?? diagnosis['needsReview'],
      ),
      mode: mode,
      requiresHitl: requiresHitl,
      confidence: _dbl(diagnosis['confidence'] ?? diagnosis['confidenceScore']),
      riskLevel: _str(diagnosis['risk_level'] ?? dd?.riskBand),
      nextSuggestedTopic: _str(
        diagnosis['next_suggested_topic'] ?? diagnosis['nextSuggestedTopic'],
      ),
      interventionPlan: interventions,
      raw: diagnosis,
      planRepaired: orchestratorResponse.payload.fallbackUsed,
      beliefEntropy: orchestratorResponse.dashboardUpdate.academic.entropy,
      formulaRecommendations: dd?.formulaRecommendations ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>> confirmHITL({
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  }) async {
    final responseData = <String, dynamic>{
      'diagnosis_id': diagnosisId,
      'approved': approved,
    };
    if (reviewerNote != null) {
      responseData['reviewer_note'] = reviewerNote;
    }

    // HITL confirmation goes through interact with a special action type.
    final response = await _api.interact(
      sessionId: sessionId,
      actionType: 'hitl_confirm',
      responseData: responseData,
    );
    return {
      'status': 'ok',
      'message': response.content,
      'data': {
        'finalMode': response.isRecovery ? 'recovery' : 'normal',
        'interventionPlan': <Map<String, dynamic>>[],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    final responseData = <String, dynamic>{
      'submission_id': submissionId,
      'diagnosis_id': diagnosisId,
      'event_name': eventName,
      'memory_scope': memoryScope,
    };
    if (reason != null) {
      responseData['reason'] = reason;
    }
    if (metadata != null) {
      responseData['metadata'] = metadata;
    }

    final response = await _api.interact(
      sessionId: sessionId,
      actionType: 'feedback',
      responseData: responseData,
    );
    return {'status': 'ok', 'message': response.content};
  }

  static String _str(Object? v) => v?.toString() ?? '';

  static double _dbl(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static List<String> _strList(Object? v) {
    if (v is! List) return <String>[];
    return v.map((e) => e.toString()).toList();
  }
}
