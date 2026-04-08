import 'api_service.dart';

enum MockDiagnosisScenario {
  autoCycle,
  diagnosisSuccess,
  hitlTriggered,
  recoveryMode,
}

class MockApiService implements ApiService {
  MockApiService({this.scenario = MockDiagnosisScenario.autoCycle});

  final MockDiagnosisScenario scenario;
  int _diagnosisCallCount = 0;

  @override
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return <String, dynamic>{
      'status': 'success',
      'message': 'Answer accepted and queued for diagnosis.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'answerId': 'ans_${DateTime.now().millisecondsSinceEpoch}',
        'questionId': questionId,
        'answerText': answer,
        'receivedAt': DateTime.now().toIso8601String(),
        'pipeline': <String, dynamic>{
          'nextStep': 'diagnosis',
          'estimatedSeconds': 1,
        },
        'context': context ?? <String, dynamic>{},
      },
      'meta': <String, dynamic>{'source': 'mock', 'schema': 'proposal-4.1.2'},
    };
  }

  @override
  Future<Map<String, dynamic>> getDiagnosis({
    required String sessionId,
    required String answerId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final activeScenario = _resolveScenario();
    final diagnosisId = 'dx_${DateTime.now().millisecondsSinceEpoch}';

    switch (activeScenario) {
      case MockDiagnosisScenario.diagnosisSuccess:
        return <String, dynamic>{
          'status': 'success',
          'message': 'Diagnosis completed.',
          'data': <String, dynamic>{
            'sessionId': sessionId,
            'answerId': answerId,
            'diagnosisId': diagnosisId,
            'title': 'Có vẻ bạn đang hơi yếu phần Đạo hàm nè',
            'gapAnalysis': 'Cần bổ trợ Đạo hàm bậc cao',
            'diagnosisReason': 'Entropy giảm, belief hội tụ về H_DERIV_GAP',
            'strengths': <String>['Quy tắc đạo hàm cơ bản'],
            'needsReview': <String>['Đạo hàm hàm số hợp'],
            'mode': 'normal',
            'requiresHITL': false,
            'recoveryMode': false,
            'riskLevel': 'low',
            'confidence': 0.91,
            'summary': 'Low stress pattern. User responds well to short tasks.',
            'interventionPlan': <Map<String, dynamic>>[
              {
                'id': 'int_breath_01',
                'title': 'Box breathing 4-4-4',
                'durationMinutes': 3,
                'type': 'breathing',
              },
              {
                'id': 'int_gratitude_01',
                'title': 'Write one gratitude note',
                'durationMinutes': 2,
                'type': 'journaling',
              },
            ],
            'hitl': null,
          },
          'meta': <String, dynamic>{'source': 'mock', 'scenario': 'success'},
        };
      case MockDiagnosisScenario.hitlTriggered:
        return <String, dynamic>{
          'status': 'success',
          'message': 'Diagnosis requires human-in-the-loop review.',
          'data': <String, dynamic>{
            'sessionId': sessionId,
            'answerId': answerId,
            'diagnosisId': diagnosisId,
            'title': 'Có vẻ bạn đang hơi yếu phần Đạo hàm nè',
            'gapAnalysis': 'Cần bổ trợ Đạo hàm hàm hợp và đạo hàm bậc cao',
            'diagnosisReason':
                'Entropy chưa ổn định, belief phân tán quanh H_CHAIN_RULE_GAP',
            'strengths': <String>['Quy tắc đạo hàm cơ bản'],
            'needsReview': <String>['Đạo hàm hàm số hợp'],
            'mode': 'hitl_pending',
            'requiresHITL': true,
            'recoveryMode': false,
            'riskLevel': 'high',
            'confidence': 0.41,
            'summary': 'High-risk keywords detected with low model confidence.',
            'interventionPlan': <Map<String, dynamic>>[],
            'hitl': <String, dynamic>{
              'ticketId': 'hitl_${DateTime.now().millisecondsSinceEpoch}',
              'status': 'pending',
              'reason': 'low_confidence_high_risk',
              'priority': 'urgent',
            },
          },
          'meta': <String, dynamic>{'source': 'mock', 'scenario': 'hitl'},
        };
      case MockDiagnosisScenario.recoveryMode:
        return <String, dynamic>{
          'status': 'success',
          'message': 'Recovery mode activated for resilient fallback flow.',
          'data': <String, dynamic>{
            'sessionId': sessionId,
            'answerId': answerId,
            'diagnosisId': diagnosisId,
            'title': 'Có vẻ bạn đang hơi yếu phần Đạo hàm nè',
            'gapAnalysis': 'Mình ưu tiên lộ trình phục hồi nhẹ trước nhé',
            'diagnosisReason':
                'Entropy tăng trở lại, hệ thống chuyển recovery để đảm bảo an toàn',
            'strengths': <String>['Quy tắc đạo hàm cơ bản'],
            'needsReview': <String>['Đạo hàm hàm số hợp'],
            'mode': 'recovery',
            'requiresHITL': false,
            'recoveryMode': true,
            'riskLevel': 'medium',
            'confidence': 0.74,
            'summary': 'Model switched to recovery-safe intervention plan.',
            'interventionPlan': <Map<String, dynamic>>[
              {
                'id': 'int_recovery_01',
                'title': 'Grounding 5-4-3-2-1',
                'durationMinutes': 5,
                'type': 'grounding',
              },
            ],
            'recovery': <String, dynamic>{
              'enabled': true,
              'reason': 'model_confidence_guardrail',
              'monitoringWindowHours': 24,
            },
          },
          'meta': <String, dynamic>{'source': 'mock', 'scenario': 'recovery'},
        };
      case MockDiagnosisScenario.autoCycle:
        throw UnimplementedError('autoCycle should be resolved before switch.');
    }
  }

  @override
  Future<Map<String, dynamic>> submitSignals({
    required String sessionId,
    required List<Map<String, dynamic>> signals,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return <String, dynamic>{
      'status': 'success',
      'message': 'Signals accepted.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'acceptedCount': signals.length,
        'receivedAt': DateTime.now().toIso8601String(),
      },
      'meta': <String, dynamic>{'source': 'mock'},
    };
  }

  @override
  Future<Map<String, dynamic>> submitInterventionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String optionId,
    required String optionLabel,
    required String mode,
    required int remainingRestSeconds,
    bool skipped = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final qValueBase = skipped ? 0.35 : 0.68;

    return <String, dynamic>{
      'status': 'success',
      'message': skipped
          ? 'Đã ghi nhận bạn muốn bỏ qua lần này, tụi mình sẽ nhẹ nhàng hơn ở lượt sau.'
          : 'Đã ghi nhận lựa chọn của bạn và cập nhật Q-values thành công.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'submissionId': submissionId,
        'diagnosisId': diagnosisId,
        'selectedOption': <String, dynamic>{
          'id': optionId,
          'label': optionLabel,
          'mode': mode,
          'remainingRestSeconds': remainingRestSeconds,
          'skipped': skipped,
        },
        'updatedQValues': <String, dynamic>{
          'review_theory':
              qValueBase + (optionId.contains('theory') ? 0.11 : 0),
          'easier_practice':
              qValueBase + (optionId.contains('practice') ? 0.09 : 0),
          'take_rest': qValueBase + (mode == 'recovery' ? 0.12 : 0),
        },
      },
      'meta': <String, dynamic>{'source': 'mock'},
    };
  }

  @override
  // ignore: non_constant_identifier_names
  Future<Map<String, dynamic>> confirmHITL({
    required String sessionId,
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return <String, dynamic>{
      'status': 'success',
      'message': approved
          ? 'HITL approved and intervention unlocked.'
          : 'HITL rejected, keep user in recovery mode.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'diagnosisId': diagnosisId,
        'hitlDecision': approved ? 'approved' : 'rejected',
        'reviewerNote': reviewerNote,
        'finalMode': approved ? 'normal' : 'recovery',
        'interventionPlan': approved
            ? <Map<String, dynamic>>[
                {
                  'id': 'int_post_hitl_01',
                  'title': 'Clinician-guided breathing set',
                  'durationMinutes': 4,
                  'type': 'breathing',
                },
              ]
            : <Map<String, dynamic>>[
                {
                  'id': 'int_recovery_fallback_01',
                  'title': 'Safe fallback grounding routine',
                  'durationMinutes': 5,
                  'type': 'grounding',
                },
              ],
      },
      'meta': <String, dynamic>{'source': 'mock'},
    };
  }

  MockDiagnosisScenario _resolveScenario() {
    if (scenario != MockDiagnosisScenario.autoCycle) {
      return scenario;
    }

    final index = _diagnosisCallCount % 3;
    _diagnosisCallCount += 1;

    if (index == 0) {
      return MockDiagnosisScenario.diagnosisSuccess;
    }
    if (index == 1) {
      return MockDiagnosisScenario.hitlTriggered;
    }
    return MockDiagnosisScenario.recoveryMode;
  }
}