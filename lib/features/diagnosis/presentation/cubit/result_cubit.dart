import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/api_models.dart';
import '../../../inspection/domain/inspection_runtime_store.dart';
import '../../data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../data/repositories/diagnosis_repository.dart';
import 'result_state.dart';

class ResultCubit extends Cubit<ResultState> {
  ResultCubit({
    required DiagnosisRepository diagnosisRepository,
    InspectionRuntimeStore? inspectionRuntimeStore,
    DiagnosisSnapshotCacheRepository? diagnosisSnapshotCacheRepository,
  }) : _diagnosisRepository = diagnosisRepository,
       _inspectionRuntimeStore =
           inspectionRuntimeStore ?? InspectionRuntimeStore.instance,
       _diagnosisSnapshotCacheRepository =
           diagnosisSnapshotCacheRepository ??
           DiagnosisSnapshotCacheRepository.instance,
       super(const ResultLoading());

  static const String _episodicMemoryScope = 'episodic_memory';

  final DiagnosisRepository _diagnosisRepository;
  final InspectionRuntimeStore _inspectionRuntimeStore;
  final DiagnosisSnapshotCacheRepository _diagnosisSnapshotCacheRepository;

  Future<void> loadResult(String submissionId) async {
    emit(const ResultLoading());

    try {
      final response = await _diagnosisRepository.getDiagnosis(
        answerId: submissionId,
      );
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final diagnosis = DiagnosisResponse.fromJson(data);
      final resolvedDiagnosisId = _resolveDiagnosisId(
        rawId: diagnosis.diagnosisId,
        submissionId: submissionId,
      );

      final strengths = _extractStringList(
        diagnosis.strengths,
      ).ifEmpty(const <String>['Quy tắc đạo hàm cơ bản']);
      final needsReview = _extractStringList(
        diagnosis.needsReview,
      ).ifEmpty(const <String>['Đạo hàm hàm số hợp']);
      final gapAnalysis = diagnosis.gapAnalysis.isNotEmpty
          ? diagnosis.gapAnalysis
          : diagnosis.summary.isNotEmpty
          ? diagnosis.summary
          : 'Cần bổ trợ Đạo hàm bậc cao';
      final diagnosisReason = _normalizeDiagnosisReason(
        raw: diagnosis.diagnosisReason,
        gapAnalysis: gapAnalysis,
        needsReview: needsReview,
      );
      final confidence = _normalizeScore(diagnosis.confidence, fallback: 0.78);
      final uncertainty = _normalizeScore(1 - confidence, fallback: 0.22);
      final finalMode = diagnosis.mode.isEmpty ? 'normal' : diagnosis.mode;
      final riskLevel = diagnosis.riskLevel.isNotEmpty
          ? diagnosis.riskLevel
          : (uncertainty >= 0.45 ? 'high' : 'low');
      final requiresHitl = diagnosis.requiresHitl;
      final nextSuggestedTopic = diagnosis.nextSuggestedTopic.isNotEmpty
          ? diagnosis.nextSuggestedTopic
          : 'Review Đạo hàm';
      final interventionPlan = _extractPlanList(diagnosis.interventionPlan);

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
                ? 'Có vẻ bạn đang hơi yếu phần Đạo hàm nè'
                : diagnosis.title,
            gapAnalysis: gapAnalysis,
            diagnosisReason: diagnosisReason,
            strengths: strengths,
            needsReview: needsReview,
            nextSuggestedTopic: nextSuggestedTopic,
            interventionPlan: interventionPlan.isEmpty
                ? _fallbackInterventionPlan(
                    finalMode: finalMode,
                    nextSuggestedTopic: nextSuggestedTopic,
                  )
                : interventionPlan,
            finalMode: finalMode,
            confidenceScore: confidence,
            uncertaintyScore: uncertainty,
            riskLevel: riskLevel,
            requiresHitl: requiresHitl,
          ),
        ),
      );
    } catch (_) {
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
          : _repairPlanTopic();

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
      final repairedTopic = _repairPlanTopic();

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
        reason: 'Người dùng từ chối đề xuất. Dùng fallback topic an toàn.',
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

  static List<Map<String, dynamic>> _fallbackInterventionPlan({
    required String finalMode,
    required String nextSuggestedTopic,
  }) {
    if (finalMode == 'recovery') {
      return const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'recovery_breathing',
          'title': 'Hít thở ngắn 3 phút rồi quay lại nhẹ nhàng',
          'type': 'recovery',
        },
        <String, dynamic>{
          'id': 'recovery_grounding',
          'title': 'Grounding 5-4-3-2-1',
          'type': 'recovery',
        },
      ];
    }

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'review_theory',
        'title': 'Ôn nhanh: $nextSuggestedTopic',
        'type': 'academic',
      },
      const <String, dynamic>{
        'id': 'easier_practice',
        'title': 'Làm 2 câu dễ để lấy lại nhịp',
        'type': 'academic',
      },
    ];
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
    final focus = _firstItemOrFallback(needsReview, gapAnalysis);

    if (source.isEmpty) {
      return 'Hệ thống nhận thấy bạn đang vướng ở "$focus", nên gợi ý một bước ôn ngắn để lấy lại đà trước khi tăng độ khó.';
    }

    final lower = source.toLowerCase();
    if (lower.contains('entropy') ||
        lower.contains('belief') ||
        lower.contains('confidence') ||
        lower.contains('h_')) {
      return 'Hệ thống nhận thấy bạn đang vướng ở "$focus", nên gợi ý một bước ôn ngắn để lấy lại đà trước khi tăng độ khó.';
    }

    return source;
  }

  static String _firstItemOrFallback(List<String> values, String fallback) {
    if (values.isEmpty) {
      return fallback;
    }

    return values.first;
  }

  static String _repairPlanTopic() {
    return 'Flashcard nhẹ nhàng';
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

    return 'dx_local_$submissionId';
  }
}

extension _FallbackList on List<String> {
  List<String> ifEmpty(List<String> fallback) {
    return isEmpty ? fallback : this;
  }
}
