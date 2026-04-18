import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/api_models.dart';
import '../../../quiz/data/models/quiz_api_models.dart';
import '../../../quiz/data/repositories/quiz_api_repository.dart';
import '../../../session/data/repositories/session_history_repository.dart';
import '../../../inspection/domain/inspection_runtime_store.dart';
import '../../data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../data/repositories/diagnosis_repository.dart';
import 'result_state.dart';

class ResultCubit extends Cubit<ResultState> {
  ResultCubit({
    required DiagnosisRepository diagnosisRepository,
    QuizApiRepository? quizApiRepository,
    SessionHistoryRepository? sessionHistoryRepository,
    InspectionRuntimeStore? inspectionRuntimeStore,
    DiagnosisSnapshotCacheRepository? diagnosisSnapshotCacheRepository,
  }) : _diagnosisRepository = diagnosisRepository,
       _quizApiRepository = quizApiRepository,
       _sessionHistoryRepository = sessionHistoryRepository,
       _inspectionRuntimeStore =
           inspectionRuntimeStore ?? InspectionRuntimeStore.instance,
       _diagnosisSnapshotCacheRepository =
           diagnosisSnapshotCacheRepository ??
           DiagnosisSnapshotCacheRepository.instance,
       super(const ResultLoading());

  static const String _episodicMemoryScope = 'episodic_memory';

  final DiagnosisRepository _diagnosisRepository;
  final QuizApiRepository? _quizApiRepository;
  final SessionHistoryRepository? _sessionHistoryRepository;
  final InspectionRuntimeStore _inspectionRuntimeStore;
  final DiagnosisSnapshotCacheRepository _diagnosisSnapshotCacheRepository;

  Future<void> loadResult(String submissionId) async {
    emit(const ResultLoading());

    QuizSessionResultResponse? sessionResult;
    if (_quizApiRepository != null) {
      try {
        sessionResult = await _quizApiRepository.getSessionResult(
          sessionId: submissionId,
        );
        await _syncSessionHistoryFromSessionResult(
          submissionId: submissionId,
          sessionResult: sessionResult,
        );
      } catch (_) {
        // Result endpoint is optional for this screen; diagnosis can still render.
      }
    }

    try {
      final diagnosis = await _diagnosisRepository.getDiagnosis(
        answerId: submissionId,
      );
      final resolvedDiagnosisId = _resolveDiagnosisId(
        rawId: diagnosis.diagnosisId,
        submissionId: submissionId,
      );

      final confidence = _resolveConfidence(
        diagnosis: diagnosis,
        sessionResult: sessionResult,
      );
      final strengths = _resolveStrengths(
        diagnosis: diagnosis,
        sessionResult: sessionResult,
      );
      final needsReview = _resolveNeedsReview(
        diagnosis: diagnosis,
        sessionResult: sessionResult,
      );
      final gapAnalysis = diagnosis.gapAnalysis.isNotEmpty
          ? diagnosis.gapAnalysis
          : diagnosis.summary.isNotEmpty
          ? diagnosis.summary
          : diagnosis.diagnosisReason.isNotEmpty
          ? diagnosis.diagnosisReason
          : _fallbackGapAnalysis(sessionResult: sessionResult);
      final diagnosisReason = _normalizeDiagnosisReason(
        raw: diagnosis.diagnosisReason,
        gapAnalysis: gapAnalysis,
        needsReview: needsReview,
      );
      final uncertainty = _normalizeScore(1 - confidence, fallback: 0.0);
      final finalMode = diagnosis.mode.isEmpty
          ? (confidence < 0.5 ? 'recovery' : 'normal')
          : diagnosis.mode;
      final riskLevel = diagnosis.riskLevel.isNotEmpty
          ? diagnosis.riskLevel
          : _riskLevelFromConfidence(confidence);
      final requiresHitl = diagnosis.requiresHitl;
      final nextSuggestedTopic = diagnosis.nextSuggestedTopic.isNotEmpty
          ? diagnosis.nextSuggestedTopic
          : needsReview.first;
      final interventionPlan = _extractPlanList(
        diagnosis.interventionPlan,
      ).ifEmpty(_fallbackInterventionPlan(nextSuggestedTopic));

      // Parse Empathy Agent / Particle Filter fields
      final raw = diagnosis.raw;
      final mentalState = (raw['mentalState'] as String?)?.isNotEmpty == true
          ? raw['mentalState'] as String
          : (finalMode == 'recovery' ? 'exhausted' : 'focused');
      final particleDistribution = _extractParticleDistribution(raw);

      await _diagnosisSnapshotCacheRepository.saveSnapshot(
        DiagnosisSnapshot(
          strengths: strengths,
          needsReview: needsReview,
          nextSuggestedTopic: nextSuggestedTopic,
          confidenceScore: confidence,
          savedAt: DateTime.now().toUtc(),
        ),
      );

      _inspectionRuntimeStore.syncFromDiagnosis(
        gapAnalysis: gapAnalysis,
        diagnosisReason: diagnosisReason,
        strengths: strengths,
        needsReview: needsReview,
        nextSuggestedTopic: nextSuggestedTopic,
        finalMode: finalMode,
        confidenceScore: confidence,
        riskLevel: riskLevel,
      );

      emit(
        ResultReady(
          result: ResultModel(
            submissionId: submissionId,
            diagnosisId: resolvedDiagnosisId,
            headline: diagnosis.title.isEmpty
                ? (gapAnalysis.isNotEmpty ? gapAnalysis : diagnosisReason)
                : diagnosis.title,
            gapAnalysis: gapAnalysis,
            diagnosisReason: diagnosisReason,
            strengths: strengths,
            needsReview: needsReview,
            nextSuggestedTopic: nextSuggestedTopic,
            interventionPlan: interventionPlan,
            finalMode: finalMode,
            confidenceScore: confidence,
            uncertaintyScore: uncertainty,
            riskLevel: riskLevel,
            requiresHitl: requiresHitl,
            mentalState: mentalState,
            particleDistribution: particleDistribution,
          ),
        ),
      );
    } catch (_) {
      if (sessionResult != null) {
        final fallbackResult = _buildFallbackResultFromSession(
          submissionId: submissionId,
          sessionResult: sessionResult,
        );

        await _diagnosisSnapshotCacheRepository.saveSnapshot(
          DiagnosisSnapshot(
            strengths: fallbackResult.strengths,
            needsReview: fallbackResult.needsReview,
            nextSuggestedTopic: fallbackResult.nextSuggestedTopic,
            confidenceScore: fallbackResult.confidenceScore,
            savedAt: DateTime.now().toUtc(),
          ),
        );

        _inspectionRuntimeStore.syncFromDiagnosis(
          gapAnalysis: fallbackResult.gapAnalysis,
          diagnosisReason: fallbackResult.diagnosisReason,
          strengths: fallbackResult.strengths,
          needsReview: fallbackResult.needsReview,
          nextSuggestedTopic: fallbackResult.nextSuggestedTopic,
          finalMode: fallbackResult.finalMode,
          confidenceScore: fallbackResult.confidenceScore,
          riskLevel: fallbackResult.riskLevel,
        );

        emit(ResultReady(result: fallbackResult));
        return;
      }

      emit(
        const ResultFailure(
          'Mình chưa tải được kết quả phân tích lần này. Bạn thử lại giúp mình nhé.',
        ),
      );
    }
  }

  Future<void> onPlanAccepted() async {
    final current = state;
    if (current is! ResultReady || current.result.diagnosisId.isEmpty) {
      return;
    }

    emit(
      current.copyWith(
        isAnalyzingFeedback: true,
        navigateToIntervention: false,
        infoMessage: null,
      ),
    );

    try {
      await _diagnosisRepository.saveInteractionFeedback(
        submissionId: current.result.submissionId,
        diagnosisId: current.result.diagnosisId,
        eventName: 'Plan Accepted',
        memoryScope: _episodicMemoryScope,
        metadata: <String, dynamic>{
          'nextSuggestedTopic': current.result.nextSuggestedTopic,
          'source': 'result_screen',
        },
      );

      _inspectionRuntimeStore.addDecision(
        action: 'Plan Accepted',
        reason:
            'Người dùng đồng ý với đề xuất ${current.result.nextSuggestedTopic}.',
        source: 'result_popup',
        uncertaintyScore: current.result.uncertaintyScore,
      );

      emit(
        current.copyWith(
          isAnalyzingFeedback: false,
          navigateToIntervention: true,
          infoMessage: null,
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isAnalyzingFeedback: false,
          infoMessage:
              'Mình chưa lưu được phản hồi lúc này. Bạn thử lại một chút nữa nhé.',
        ),
      );
    }
  }

  Future<void> onPlanRejected() async {
    final current = state;
    if (current is! ResultReady || current.result.diagnosisId.isEmpty) {
      return;
    }

    emit(
      current.copyWith(
        isAnalyzingFeedback: true,
        navigateToIntervention: false,
        infoMessage: null,
      ),
    );

    try {
      final response = await _diagnosisRepository.saveInteractionFeedback(
        submissionId: current.result.submissionId,
        diagnosisId: current.result.diagnosisId,
        eventName: 'Plan Rejected',
        memoryScope: _episodicMemoryScope,
        reason: 'User wants to skip',
        metadata: <String, dynamic>{
          'originalTopic': current.result.nextSuggestedTopic,
          'source': 'result_screen',
        },
      );

      final payload = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final interactionResponse = InteractionFeedbackResponse.fromJson(payload);

      final repairedTopic = interactionResponse.nextSuggestedTopic.isNotEmpty
          ? interactionResponse.nextSuggestedTopic
          : current.result.nextSuggestedTopic;

      _inspectionRuntimeStore.addDecision(
        action: 'Plan Rejected',
        reason:
            'Người dùng từ chối đề xuất ban đầu. Chuyển sang $repairedTopic.',
        source: 'result_popup',
        uncertaintyScore: current.result.uncertaintyScore,
      );

      _inspectionRuntimeStore.syncFromDiagnosis(
        gapAnalysis: current.result.gapAnalysis,
        diagnosisReason: current.result.diagnosisReason,
        strengths: current.result.strengths,
        needsReview: current.result.needsReview,
        nextSuggestedTopic: repairedTopic,
        finalMode: current.result.finalMode,
        confidenceScore: current.result.confidenceScore,
        riskLevel: current.result.riskLevel,
      );

      emit(
        current.copyWith(
          isAnalyzingFeedback: false,
          result: current.result.copyWith(nextSuggestedTopic: repairedTopic),
          infoMessage: 'Lộ trình học của bạn đã được cập nhật',
          navigateToIntervention: true,
        ),
      );
    } catch (_) {
      final repairedTopic = current.result.nextSuggestedTopic;

      _inspectionRuntimeStore.syncFromDiagnosis(
        gapAnalysis: current.result.gapAnalysis,
        diagnosisReason: current.result.diagnosisReason,
        strengths: current.result.strengths,
        needsReview: current.result.needsReview,
        nextSuggestedTopic: repairedTopic,
        finalMode: current.result.finalMode,
        confidenceScore: current.result.confidenceScore,
        riskLevel: current.result.riskLevel,
      );

      emit(
        current.copyWith(
          isAnalyzingFeedback: false,
          result: current.result.copyWith(nextSuggestedTopic: repairedTopic),
          infoMessage: 'Lộ trình học của bạn đã được cập nhật',
          navigateToIntervention: true,
        ),
      );

      _inspectionRuntimeStore.addDecision(
        action: 'Plan Rejected',
        reason: 'Người dùng từ chối đề xuất và giữ chủ đề hiện tại.',
        source: 'result_popup',
        uncertaintyScore: current.result.uncertaintyScore,
      );
    }
  }

  void clearInfoMessage() {
    final current = state;
    if (current is! ResultReady || current.infoMessage == null) {
      return;
    }

    emit(current.copyWith(infoMessage: null));
  }

  void clearNavigationFlag() {
    final current = state;
    if (current is! ResultReady || !current.navigateToIntervention) {
      return;
    }

    emit(current.copyWith(navigateToIntervention: false));
  }

  static List<String> _extractStringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }

    return value.map((item) => item.toString()).toList();
  }

  static List<Map<String, dynamic>> _extractPlanList(Object? value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static String _normalizeDiagnosisReason({
    required String? raw,
    required String gapAnalysis,
    required List<String> needsReview,
  }) {
    final source = (raw ?? '').trim();
    if (source.isNotEmpty) {
      return source;
    }

    final normalizedGap = gapAnalysis.trim();
    if (normalizedGap.isNotEmpty) {
      return normalizedGap;
    }

    return needsReview.isEmpty ? '' : needsReview.first;
  }

  static double _normalizeScore(Object? value, {required double fallback}) {
    final candidate = switch (value) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text),
      _ => null,
    };

    if (candidate == null || candidate.isNaN || candidate.isInfinite) {
      return fallback;
    }

    if (candidate < 0) {
      return 0;
    }

    if (candidate > 1) {
      return 1;
    }

    return candidate;
  }

  static String _resolveDiagnosisId({
    required String? rawId,
    required String submissionId,
  }) {
    final candidate = (rawId ?? '').trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }

    return submissionId;
  }

  static Map<String, double> _extractParticleDistribution(
    Map<String, dynamic> data,
  ) {
    final raw = data['particleDistribution'];
    if (raw is! Map) {
      return const <String, double>{};
    }
    final result = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      if (key == null) continue;
      final value = switch (entry.value) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s),
        _ => null,
      };
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  ResultModel _buildFallbackResultFromSession({
    required String submissionId,
    required QuizSessionResultResponse sessionResult,
  }) {
    final confidence = _normalizeScore(
      sessionResult.summary.accuracyPercent / 100,
      fallback: 0,
    );
    final strengths = _fallbackStrengths(sessionResult: sessionResult);
    final needsReview = _fallbackNeedsReview(sessionResult: sessionResult);
    final nextSuggestedTopic = needsReview.first;
    final gapAnalysis = _fallbackGapAnalysis(sessionResult: sessionResult);
    final finalMode = confidence < 0.5 ? 'recovery' : 'normal';

    return ResultModel(
      submissionId: submissionId,
      diagnosisId: _resolveDiagnosisId(rawId: null, submissionId: submissionId),
      headline: gapAnalysis,
      gapAnalysis: gapAnalysis,
      diagnosisReason: gapAnalysis,
      strengths: strengths,
      needsReview: needsReview,
      nextSuggestedTopic: nextSuggestedTopic,
      interventionPlan: _fallbackInterventionPlan(nextSuggestedTopic),
      finalMode: finalMode,
      confidenceScore: confidence,
      uncertaintyScore: _normalizeScore(1 - confidence, fallback: 0),
      riskLevel: _riskLevelFromConfidence(confidence),
      requiresHitl: false,
      mentalState: finalMode == 'recovery' ? 'tired' : 'focused',
      particleDistribution: const <String, double>{},
    );
  }

  Future<void> _syncSessionHistoryFromSessionResult({
    required String submissionId,
    required QuizSessionResultResponse sessionResult,
  }) async {
    final sessionHistoryRepository = _sessionHistoryRepository;
    if (sessionHistoryRepository == null) {
      return;
    }

    final sessionId = sessionResult.sessionId.isNotEmpty
        ? sessionResult.sessionId
        : submissionId;
    final confidence = _normalizeScore(
      sessionResult.summary.accuracyPercent / 100,
      fallback: 0,
    );
    final completedAt =
        sessionResult.endedAt ?? sessionResult.startedAt ?? DateTime.now();

    await sessionHistoryRepository.upsertCompletedSession(
      sourceKey: 'session:$sessionId',
      topic: _deriveTopicFromSessionId(sessionId),
      mode: sessionResult.sessionStatus.toLowerCase() == 'abandoned'
          ? 'recovery'
          : 'academic',
      durationMinutes: _deriveDurationMinutes(
        answeredCount: sessionResult.summary.answeredCount,
      ),
      focusScore: (confidence * 4).clamp(0.0, 4.0).toDouble(),
      confidenceScore: confidence,
      nextAction: _deriveNextActionFromConfidence(confidence),
      completedAt: completedAt,
    );
  }

  static double _resolveConfidence({
    required DiagnosisResponse diagnosis,
    required QuizSessionResultResponse? sessionResult,
  }) {
    final fromDiagnosis = _normalizeScore(diagnosis.confidence, fallback: 0);
    if (fromDiagnosis > 0) {
      return fromDiagnosis;
    }
    if (sessionResult == null) {
      return fromDiagnosis;
    }
    return _normalizeScore(
      sessionResult.summary.accuracyPercent / 100,
      fallback: 0,
    );
  }

  static List<String> _resolveStrengths({
    required DiagnosisResponse diagnosis,
    required QuizSessionResultResponse? sessionResult,
  }) {
    final fromDiagnosis = _extractStringList(diagnosis.strengths);
    if (fromDiagnosis.isNotEmpty) {
      return fromDiagnosis;
    }
    return _fallbackStrengths(sessionResult: sessionResult);
  }

  static List<String> _resolveNeedsReview({
    required DiagnosisResponse diagnosis,
    required QuizSessionResultResponse? sessionResult,
  }) {
    final fromDiagnosis = _extractStringList(diagnosis.needsReview);
    if (fromDiagnosis.isNotEmpty) {
      return fromDiagnosis;
    }
    return _fallbackNeedsReview(sessionResult: sessionResult);
  }

  static List<String> _fallbackStrengths({
    required QuizSessionResultResponse? sessionResult,
  }) {
    if (sessionResult == null) {
      return const <String>['Bạn đã hoàn thành phiên học'];
    }

    final correct = sessionResult.summary.correctCount;
    final total = sessionResult.summary.answeredCount;
    if (total > 0 && correct > 0) {
      return <String>['Đúng $correct/$total câu trong phiên vừa rồi'];
    }

    return const <String>['Bạn đã hoàn thành phiên học'];
  }

  static List<String> _fallbackNeedsReview({
    required QuizSessionResultResponse? sessionResult,
  }) {
    final accuracy = sessionResult == null
        ? 0.0
        : _normalizeScore(
            sessionResult.summary.accuracyPercent / 100,
            fallback: 0,
          );

    if (accuracy >= 0.85) {
      return const <String>['Tăng nhẹ độ khó ở phiên kế tiếp'];
    }
    if (accuracy >= 0.6) {
      return const <String>['Ôn lại nhóm câu sai và luyện thêm 2 câu tương tự'];
    }
    return const <String>['Ôn lại khái niệm cốt lõi trước khi tăng độ khó'];
  }

  static String _fallbackGapAnalysis({
    required QuizSessionResultResponse? sessionResult,
  }) {
    if (sessionResult == null) {
      return 'Hệ thống đã cập nhật tiến trình phiên học của bạn.';
    }

    final correct = sessionResult.summary.correctCount;
    final total = sessionResult.summary.answeredCount;
    final accuracy = sessionResult.summary.accuracyPercent.toStringAsFixed(0);
    return 'Bạn đã hoàn thành $correct/$total câu (độ chính xác $accuracy%).';
  }

  static List<Map<String, dynamic>> _fallbackInterventionPlan(String topic) {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'review_focus_topic',
        'title': 'Ôn trọng tâm: $topic',
        'type': 'academic',
      },
      const <String, dynamic>{
        'id': 'practice_followup',
        'title': 'Làm thêm 2 câu cùng dạng',
        'type': 'academic',
      },
    ];
  }

  static String _riskLevelFromConfidence(double confidence) {
    if (confidence >= 0.75) {
      return 'low';
    }
    if (confidence >= 0.45) {
      return 'medium';
    }
    return 'high';
  }

  static String _deriveTopicFromSessionId(String sessionId) {
    final suffix = sessionId.length > 8
        ? sessionId.substring(sessionId.length - 8)
        : sessionId;
    return 'Phiên quiz #$suffix';
  }

  static int _deriveDurationMinutes({required int answeredCount}) {
    final estimated = answeredCount <= 0 ? 8 : answeredCount * 2;
    return estimated.clamp(5, 120).toInt();
  }

  static String _deriveNextActionFromConfidence(double confidence) {
    if (confidence >= 0.85) {
      return 'Tăng nhẹ độ khó ở phiên sau';
    }
    if (confidence >= 0.6) {
      return 'Ôn lại 1 chủ điểm chính rồi làm tiếp 2 câu';
    }
    return 'Ôn lại lý thuyết nền tảng trước khi làm tiếp';
  }
}

extension _ListFallbackExtension<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) {
    return isEmpty ? fallback : this;
  }
}
