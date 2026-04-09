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
  final Map<String, String> _answerById = <String, String>{};

  @override
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final answerId = 'ans_${DateTime.now().millisecondsSinceEpoch}';
    final isCorrect = _isCorrectDerivativeAnswer(answer);
    _answerById[answerId] = answer;

    return <String, dynamic>{
      'status': 'success',
      'message': 'Answer accepted and queued for diagnosis.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'answerId': answerId,
        'questionId': questionId,
        'answerText': answer,
        'isCorrect': isCorrect,
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

    final submittedAnswer = _answerById[answerId] ?? '';
    final answerIsCorrect = _isCorrectDerivativeAnswer(submittedAnswer);

    if (scenario == MockDiagnosisScenario.autoCycle && answerIsCorrect) {
      final diagnosisId = 'dx_${DateTime.now().millisecondsSinceEpoch}';
      return _buildCorrectAnswerDiagnosis(
        sessionId: sessionId,
        answerId: answerId,
        diagnosisId: diagnosisId,
      );
    }

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
            'diagnosisReason':
                'Mình thấy bạn đang chững ở Đạo hàm bậc cao, nên đề xuất ôn lại theo từng bước ngắn để chắc nền.',
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
                'Hệ thống chưa đủ chắc chắn ở phần Đạo hàm hàm hợp, nên cần thêm xác nhận để tránh gợi ý quá sức.',
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
                'Mức tập trung đang dao động, nên mình chuyển sang lộ trình phục hồi nhẹ để bạn lấy lại nhịp.',
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

  @override
  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(milliseconds: 650));

    final repairedTopic = eventName == 'Plan Rejected'
        ? 'Flashcard nhẹ nhàng'
        : 'Review Đạo hàm';

    return <String, dynamic>{
      'status': 'success',
      'message': 'Interaction feedback stored in episodic memory.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'submissionId': submissionId,
        'diagnosisId': diagnosisId,
        'eventName': eventName,
        'memoryScope': memoryScope,
        'reason': reason,
        'nextSuggestedTopic': repairedTopic,
        'eventId': 'epi_${DateTime.now().millisecondsSinceEpoch}',
        'savedAt': DateTime.now().toIso8601String(),
        'metadata': metadata ?? <String, dynamic>{},
      },
      'meta': <String, dynamic>{'source': 'mock', 'table': 'episodic_memory'},
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

  bool _isCorrectDerivativeAnswer(String rawAnswer) {
    var normalized = rawAnswer
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('*', '')
        .replaceAll('−', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');

    normalized = normalized.replaceAllMapped(
      RegExp(r"^((y'|y’|dy/dx|f\(x\)|f'\(x\)|y)=?)"),
      (_) => '',
    );

    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }

    const acceptedForms = <String>{
      '12x^2+4x',
      '4x+12x^2',
      '12x^2+4x+0',
      '4x+12x^2+0',
    };

    return acceptedForms.contains(normalized);
  }

  Map<String, dynamic> _buildCorrectAnswerDiagnosis({
    required String sessionId,
    required String answerId,
    required String diagnosisId,
  }) {
    return <String, dynamic>{
      'status': 'success',
      'message': 'Diagnosis completed.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'answerId': answerId,
        'diagnosisId': diagnosisId,
        'title': 'Bạn làm đúng phần Đạo hàm rồi nè',
        'gapAnalysis': 'Bài này bạn làm đúng: y\' = 12x^2 + 4x.',
        'diagnosisReason':
            'Đối chiếu biểu thức cho thấy đáp án tương đương với đạo hàm chuẩn.',
        'strengths': <String>['Áp dụng đúng quy tắc đạo hàm lũy thừa'],
        'needsReview': <String>['Có thể luyện thêm tốc độ trình bày'],
        'mode': 'normal',
        'requiresHITL': false,
        'recoveryMode': false,
        'riskLevel': 'low',
        'confidence': 0.98,
        'summary': 'User solved derivative correctly with stable confidence.',
        'interventionPlan': <Map<String, dynamic>>[
          {
            'id': 'int_boost_01',
            'title': 'Tiếp tục với 1 bài nâng nhẹ',
            'durationMinutes': 4,
            'type': 'practice',
          },
        ],
        'hitl': null,
      },
      'meta': <String, dynamic>{'source': 'mock', 'scenario': 'correct_answer'},
    };
  }
}
