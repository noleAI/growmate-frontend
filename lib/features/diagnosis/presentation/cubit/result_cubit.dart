import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../inspection/domain/inspection_runtime_store.dart';
import '../../data/repositories/diagnosis_repository.dart';
import 'result_state.dart';

class ResultCubit extends Cubit<ResultState> {
  ResultCubit({
    required DiagnosisRepository diagnosisRepository,
    InspectionRuntimeStore? inspectionRuntimeStore,
  }) : _diagnosisRepository = diagnosisRepository,
       _inspectionRuntimeStore =
           inspectionRuntimeStore ?? InspectionRuntimeStore.instance,
       super(const ResultLoading());

  static const String _episodicMemoryScope = 'episodic_memory';

  final DiagnosisRepository _diagnosisRepository;
  final InspectionRuntimeStore _inspectionRuntimeStore;

  Future<void> loadResult(String submissionId) async {
    emit(const ResultLoading());

    try {
      final response = await _diagnosisRepository.getDiagnosis(
        answerId: submissionId,
      );
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final strengths = _extractStringList(
        data['strengths'],
      ).ifEmpty(const <String>['Quy tắc đạo hàm cơ bản']);
      final needsReview = _extractStringList(
        data['needsReview'],
      ).ifEmpty(const <String>['Đạo hàm hàm số hợp']);
      final gapAnalysis =
          data['gapAnalysis']?.toString() ??
          data['summary']?.toString() ??
          'Cần bổ trợ Đạo hàm bậc cao';
      final diagnosisReason = _normalizeDiagnosisReason(
        raw: data['diagnosisReason']?.toString(),
        gapAnalysis: gapAnalysis,
        needsReview: needsReview,
      );
      final confidence = _normalizeScore(data['confidence'], fallback: 0.78);
      final uncertainty = _normalizeScore(1 - confidence, fallback: 0.22);
      final finalMode = data['mode']?.toString() ?? 'normal';
      final riskLevel =
          data['riskLevel']?.toString() ??
          (uncertainty >= 0.45 ? 'high' : 'low');
      final requiresHitl = data['requiresHITL'] == true;
      final nextSuggestedTopic =
          data['nextSuggestedTopic']?.toString() ?? 'Review Đạo hàm';

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
            diagnosisId: data['diagnosisId']?.toString() ?? '',
            headline:
                data['title']?.toString() ??
                'Có vẻ bạn đang hơi yếu phần Đạo hàm nè',
            gapAnalysis: gapAnalysis,
            diagnosisReason: diagnosisReason,
            strengths: strengths,
            needsReview: needsReview,
            nextSuggestedTopic: nextSuggestedTopic,
            interventionPlan: _extractPlanList(data['interventionPlan']),
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
        navigateToNextQuiz: false,
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
          navigateToNextQuiz: true,
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
        navigateToNextQuiz: false,
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

      final repairedTopic =
          payload['nextSuggestedTopic']?.toString() ?? _repairPlanTopic();

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
    if (current is! ResultReady || !current.navigateToNextQuiz) {
      return;
    }

    emit(current.copyWith(navigateToNextQuiz: false));
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
}

extension _FallbackList on List<String> {
  List<String> ifEmpty(List<String> fallback) {
    return isEmpty ? fallback : this;
  }
}
