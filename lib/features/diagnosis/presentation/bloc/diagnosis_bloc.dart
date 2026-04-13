import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/api_models.dart';
import '../../data/repositories/diagnosis_repository.dart';
import 'diagnosis_event.dart';
import 'diagnosis_state.dart';

class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  DiagnosisBloc({required DiagnosisRepository diagnosisRepository})
    : _diagnosisRepository = diagnosisRepository,
      super(const DiagnosisLoading()) {
    on<DiagnosisRequested>(_onDiagnosisRequested);
    on<HITLConfirmed>(_onHitlConfirmed);
  }

  final DiagnosisRepository _diagnosisRepository;

  Future<void> _onDiagnosisRequested(
    DiagnosisRequested event,
    Emitter<DiagnosisState> emit,
  ) async {
    emit(const DiagnosisLoading());

    try {
      final response = await _diagnosisRepository.getDiagnosis(
        answerId: event.submissionId,
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final diagnosis = DiagnosisResponse.fromJson(data);

      emit(
        DiagnosisSuccess(
          submissionId: event.submissionId,
          diagnosisId: diagnosis.diagnosisId,
          headline: diagnosis.title.isEmpty
              ? 'Có vẻ bạn đang hơi yếu phần Đạo hàm nè'
              : diagnosis.title,
          gapAnalysis: diagnosis.gapAnalysis.isNotEmpty
              ? diagnosis.gapAnalysis
              : diagnosis.summary.isNotEmpty
              ? diagnosis.summary
              : 'Cần bổ trợ Đạo hàm bậc cao',
          strengths: _extractStringList(
            diagnosis.strengths,
          ).ifEmpty(['Quy tắc đạo hàm cơ bản']),
          needsReview: _extractStringList(
            diagnosis.needsReview,
          ).ifEmpty(['Đạo hàm hàm số hợp']),
          diagnosisReason: diagnosis.diagnosisReason.isEmpty
              ? 'Entropy giảm, belief hội tụ về H_DERIV_GAP'
              : diagnosis.diagnosisReason,
          interventionPlan: _extractPlanList(diagnosis.interventionPlan),
          finalMode: diagnosis.mode.isEmpty ? 'normal' : diagnosis.mode,
          requiresHitl: diagnosis.requiresHitl,
        ),
      );
    } catch (_) {
      emit(
        const DiagnosisFailure(
          'Mình chưa lấy được kết quả chẩn đoán. Thử lại giúp mình nhé.',
        ),
      );
    }
  }

  Future<void> _onHitlConfirmed(
    HITLConfirmed event,
    Emitter<DiagnosisState> emit,
  ) async {
    final current = state;
    if (current is! DiagnosisSuccess || current.diagnosisId.isEmpty) {
      return;
    }

    emit(current.copyWith(isConfirming: true, infoMessage: null));

    try {
      final response = await _diagnosisRepository.confirmHITL(
        diagnosisId: current.diagnosisId,
        approved: event.approved,
        reviewerNote: event.reviewerNote,
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final hitlResponse = HITLConfirmResponse.fromJson(data);
      final updatedPlan = _extractPlanList(hitlResponse.interventionPlan);

      emit(
        current.copyWith(
          isConfirming: false,
          hitlConfirmed: true,
          requiresHitl: false,
          finalMode: hitlResponse.finalMode.isEmpty
              ? current.finalMode
              : hitlResponse.finalMode,
          interventionPlan: updatedPlan.isEmpty
              ? current.interventionPlan
              : updatedPlan,
          infoMessage:
              response['message']?.toString() ??
              'Đã xác nhận, tụi mình chuyển sang bước tiếp theo nhé.',
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isConfirming: false,
          infoMessage: 'Xác nhận tạm lỗi. Mình thử lại một lần nữa nhé.',
        ),
      );
    }
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
        .map((map) => Map<String, dynamic>.from(map))
        .toList();
  }
}

extension _FallbackList on List<String> {
  List<String> ifEmpty(List<String> fallback) {
    return isEmpty ? fallback : this;
  }
}
