import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_service.dart';
import '../network/mock_api_service.dart';

class SupabaseHybridApiService implements ApiService {
  SupabaseHybridApiService({
    ApiService? fallbackApiService,
    SupabaseClient? supabaseClient,
  }) : _fallbackApiService =
           fallbackApiService ??
           MockApiService(scenario: MockDiagnosisScenario.autoCycle),
       _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient();

  final ApiService _fallbackApiService;
  final SupabaseClient? _supabaseClient;

  String? _cachedLearningSessionId;

  @override
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) {
    return _fallbackApiService.submitAnswer(
      sessionId: sessionId,
      questionId: questionId,
      answer: answer,
      context: context,
    );
  }

  @override
  Future<Map<String, dynamic>> getDiagnosis({
    required String sessionId,
    required String answerId,
  }) {
    return _fallbackApiService.getDiagnosis(
      sessionId: sessionId,
      answerId: answerId,
    );
  }

  @override
  Future<Map<String, dynamic>> submitSignals({
    required String sessionId,
    required List<Map<String, dynamic>> signals,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      return _fallbackApiService.submitSignals(
        sessionId: sessionId,
        signals: signals,
      );
    }

    try {
      final resolvedSessionId = await _ensureLearningSessionId(sessionId);
      if (resolvedSessionId.isEmpty) {
        return _fallbackApiService.submitSignals(
          sessionId: sessionId,
          signals: signals,
        );
      }

      final normalizedSignals = signals
          .map(_normalizeSignalPayload)
          .toList(growable: false);

      final rpcResult = await client.rpc(
        'insert_behavioral_signals_batch',
        params: <String, dynamic>{
          'p_session_id': resolvedSessionId,
          'p_signals': normalizedSignals,
        },
      );

      final acceptedCount = _toInt(rpcResult) ?? normalizedSignals.length;

      return <String, dynamic>{
        'status': 'success',
        'message': 'Signals accepted by Supabase.',
        'data': <String, dynamic>{
          'sessionId': resolvedSessionId,
          'acceptedCount': acceptedCount,
        },
        'meta': <String, dynamic>{'source': 'supabase-rpc'},
      };
    } catch (_) {
      return _fallbackApiService.submitSignals(
        sessionId: sessionId,
        signals: signals,
      );
    }
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
    final client = _supabaseClient;
    if (client == null) {
      return _fallbackApiService.submitInterventionFeedback(
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

    try {
      final resolvedSessionId = await _ensureLearningSessionId(sessionId);
      if (resolvedSessionId.isEmpty) {
        return _fallbackApiService.submitInterventionFeedback(
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

      final stateKey =
          'mode:$mode|rest:$remainingRestSeconds|submission:$submissionId';
      final reward = _rewardForIntervention(
        mode: mode,
        optionId: optionId,
        skipped: skipped,
      );

      final qResult = await client.rpc(
        'upsert_q_value',
        params: <String, dynamic>{
          'p_state_discretized': stateKey,
          'p_action': optionId,
          'p_reward': reward,
          'p_alpha': 0.2,
        },
      );

      final qValue = _extractQValue(qResult) ?? reward;

      try {
        await client.rpc(
          'insert_audit_event',
          params: <String, dynamic>{
            'p_session_id': resolvedSessionId,
            'p_event_type': 'intervention_feedback',
            'p_context': <String, dynamic>{
              'submission_id': submissionId,
              'diagnosis_id': diagnosisId,
              'option_id': optionId,
              'mode': mode,
              'skipped': skipped,
            },
            'p_hitl_triggered': false,
          },
        );
      } catch (_) {
        // Keep UI flow smooth even if audit write fails.
      }

      return <String, dynamic>{
        'status': 'success',
        'message': skipped
            ? 'Da ghi nhan bo qua lan nay.'
            : 'Da ghi nhan lua chon va cap nhat q value.',
        'data': <String, dynamic>{
          'sessionId': resolvedSessionId,
          'submissionId': submissionId,
          'diagnosisId': diagnosisId,
          'selectedOption': <String, dynamic>{
            'id': optionId,
            'label': optionLabel,
            'mode': mode,
            'remainingRestSeconds': remainingRestSeconds,
            'skipped': skipped,
          },
          'updatedQValues': <String, dynamic>{optionId: qValue},
        },
        'meta': <String, dynamic>{'source': 'supabase-rpc'},
      };
    } catch (_) {
      return _fallbackApiService.submitInterventionFeedback(
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

  @override
  // ignore: non_constant_identifier_names
  Future<Map<String, dynamic>> confirmHITL({
    required String sessionId,
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  }) {
    return _fallbackApiService.confirmHITL(
      sessionId: sessionId,
      diagnosisId: diagnosisId,
      approved: approved,
      reviewerNote: reviewerNote,
    );
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
    final client = _supabaseClient;
    if (client == null) {
      return _fallbackApiService.saveInteractionFeedback(
        sessionId: sessionId,
        submissionId: submissionId,
        diagnosisId: diagnosisId,
        eventName: eventName,
        memoryScope: memoryScope,
        reason: reason,
        metadata: metadata,
      );
    }

    try {
      final resolvedSessionId = await _ensureLearningSessionId(sessionId);
      if (resolvedSessionId.isEmpty) {
        return _fallbackApiService.saveInteractionFeedback(
          sessionId: sessionId,
          submissionId: submissionId,
          diagnosisId: diagnosisId,
          eventName: eventName,
          memoryScope: memoryScope,
          reason: reason,
          metadata: metadata,
        );
      }

      final rpcResult = await client.rpc(
        'save_interaction_feedback',
        params: <String, dynamic>{
          'p_session_id': resolvedSessionId,
          'p_submission_id': submissionId,
          'p_diagnosis_id': diagnosisId,
          'p_event_name': eventName,
          'p_memory_scope': memoryScope,
          'p_reason': reason,
          'p_metadata': metadata ?? <String, dynamic>{},
        },
      );

      final payload = rpcResult is Map
          ? Map<String, dynamic>.from(rpcResult)
          : <String, dynamic>{};

      return <String, dynamic>{
        'status': 'success',
        'message': 'Interaction feedback stored in Supabase.',
        'data': <String, dynamic>{
          'sessionId': resolvedSessionId,
          'submissionId': submissionId,
          'diagnosisId': diagnosisId,
          'eventId': payload['event_id']?.toString(),
          'nextSuggestedTopic':
              payload['nextSuggestedTopic']?.toString() ?? 'Review Dao ham',
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'metadata': metadata ?? <String, dynamic>{},
        },
        'meta': <String, dynamic>{'source': 'supabase-rpc'},
      };
    } catch (_) {
      return _fallbackApiService.saveInteractionFeedback(
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

  Future<String> _ensureLearningSessionId(String requestedSessionId) async {
    final client = _supabaseClient;
    if (client == null) {
      return requestedSessionId;
    }

    final userId = client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return requestedSessionId;
    }

    if (_cachedLearningSessionId != null &&
        _cachedLearningSessionId!.isNotEmpty) {
      return _cachedLearningSessionId!;
    }

    final rpcResult = await client.rpc('start_learning_session');
    final sessionId = rpcResult?.toString() ?? '';

    if (sessionId.isEmpty) {
      return requestedSessionId;
    }

    _cachedLearningSessionId = sessionId;
    return sessionId;
  }

  static Map<String, dynamic> _normalizeSignalPayload(
    Map<String, dynamic> signal,
  ) {
    final typingSpeed =
        _toDouble(signal['typing_speed']) ?? _toDouble(signal['typingSpeed']);
    final correctionRate =
        _toDouble(signal['correction_rate']) ??
        _toDouble(signal['correctionRate']);
    final idleTime =
        _toDouble(signal['idle_time']) ?? _toDouble(signal['idleTime']);
    final createdAt =
        signal['created_at']?.toString() ??
        signal['captured_at']?.toString() ??
        DateTime.now().toUtc().toIso8601String();

    return <String, dynamic>{
      'typing_speed': typingSpeed ?? 0,
      'correction_rate': correctionRate ?? 0,
      'idle_time': idleTime ?? 0,
      'created_at': createdAt,
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static double _rewardForIntervention({
    required String mode,
    required String optionId,
    required bool skipped,
  }) {
    if (skipped) {
      return -0.1;
    }

    if (mode == 'recovery') {
      return 0.6;
    }

    if (optionId.contains('practice')) {
      return 0.8;
    }

    if (optionId.contains('theory')) {
      return 0.7;
    }

    return 0.65;
  }

  static double? _extractQValue(Object? rpcResult) {
    if (rpcResult is List && rpcResult.isNotEmpty) {
      final first = rpcResult.first;
      if (first is Map && first['q_value'] != null) {
        return _toDouble(first['q_value']);
      }
    }

    if (rpcResult is Map && rpcResult['q_value'] != null) {
      return _toDouble(rpcResult['q_value']);
    }

    return null;
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> submitBatchAnswers({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) {
    return _fallbackApiService.submitBatchAnswers(
      sessionId: sessionId,
      answers: answers,
    );
  }
}
