import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../inspection/domain/inspection_runtime_store.dart';
import '../../../notification/data/repositories/notification_repository.dart';
import '../../data/repositories/intervention_repository.dart';
import 'intervention_event.dart';
import 'intervention_state.dart';

class InterventionBloc extends Bloc<InterventionEvent, InterventionState> {
  InterventionBloc({
    required InterventionRepository interventionRepository,
    required this.submissionId,
    required this.diagnosisId,
    required this.finalMode,
    required List<Map<String, dynamic>> backendInterventionPlan,
    required this.uncertaintyHigh,
    InspectionRuntimeStore? inspectionRuntimeStore,
    NotificationRepository? notificationRepository,
  }) : _interventionRepository = interventionRepository,
       _backendInterventionPlan = backendInterventionPlan,
       _inspectionRuntimeStore =
           inspectionRuntimeStore ?? InspectionRuntimeStore.instance,
       _notificationRepository =
           notificationRepository ?? NotificationRepository.instance,
       super(
         const InterventionState(
           mode: InterventionMode.academic,
           options: <InterventionOption>[],
           remainingRestSeconds: _defaultRecoverySeconds,
           isSubmitting: false,
           showUncertaintyPrompt: false,
           feedbackRecorded: false,
         ),
       ) {
    on<InterventionStarted>(_onInterventionStarted);
    on<InterventionOptionSelected>(_onInterventionOptionSelected);
    on<InterventionPromptResolved>(_onInterventionPromptResolved);
    on<InterventionMessageCleared>(_onInterventionMessageCleared);
    on<RecoveryTicked>(_onRecoveryTicked);
  }

  static const int _defaultRecoverySeconds = 299;

  final InterventionRepository _interventionRepository;
  final String submissionId;
  final String diagnosisId;
  final String finalMode;
  final List<Map<String, dynamic>> _backendInterventionPlan;
  final bool uncertaintyHigh;
  final InspectionRuntimeStore _inspectionRuntimeStore;
  final NotificationRepository _notificationRepository;

  Timer? _recoveryTimer;

  Future<void> _onInterventionStarted(
    InterventionStarted event,
    Emitter<InterventionState> emit,
  ) async {
    final initialMode = finalMode == 'recovery'
        ? InterventionMode.recovery
        : InterventionMode.academic;
    final options = _buildOptionsFromBackend(_backendInterventionPlan);

    emit(
      state.copyWith(
        mode: initialMode,
        options: options,
        remainingRestSeconds: _defaultRecoverySeconds,
        showUncertaintyPrompt: uncertaintyHigh,
        toastMessage: null,
      ),
    );

    if (uncertaintyHigh) {
      _inspectionRuntimeStore.addDecision(
        action: 'HITL Prompt Triggered',
        reason:
            'Độ bất định cao trong pha intervention, cần người dùng xác nhận hướng hỗ trợ.',
        source: 'intervention',
      );
    }

    _inspectionRuntimeStore.updateMentalState(
      label: initialMode == InterventionMode.recovery
          ? 'Hơi mệt'
          : 'Bối rối nhẹ',
      hint: initialMode == InterventionMode.recovery
          ? 'Đang ưu tiên nhịp học phục hồi và giảm tải.'
          : 'Đang giữ nhịp học với can thiệp hỗ trợ vừa phải.',
    );

    _syncRecoveryTimer(initialMode, _defaultRecoverySeconds);

    await _notificationRepository.pushInterventionEvent(
      submissionId: submissionId,
      diagnosisId: diagnosisId,
      mode: initialMode == InterventionMode.recovery ? 'recovery' : 'normal',
    );
  }

  Future<void> _onInterventionOptionSelected(
    InterventionOptionSelected event,
    Emitter<InterventionState> emit,
  ) async {
    if (state.isSubmitting) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, toastMessage: null));

    try {
      final modeLabel = state.mode == InterventionMode.recovery
          ? 'recovery'
          : 'academic';

      final response = await _interventionRepository.submitFeedback(
        submissionId: submissionId,
        diagnosisId: diagnosisId,
        optionId: event.option.id,
        optionLabel: event.option.label,
        mode: modeLabel,
        remainingRestSeconds: state.remainingRestSeconds,
        skipped: event.option.id == 'skip_once',
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final qValues = data['updatedQValues'] is Map<String, dynamic>
          ? data['updatedQValues'] as Map<String, dynamic>
          : <String, dynamic>{};

      _inspectionRuntimeStore.updateQValues(qValues);
      _inspectionRuntimeStore.addDecision(
        action: 'Intervention Selected: ${event.option.label}',
        reason:
            response['message']?.toString() ??
            'Đã ghi nhận phản hồi intervention từ người dùng.',
        source: 'intervention',
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackRecorded: true,
          updatedQValues: qValues,
          selectedOptionLabel: event.option.label,
          selectedOptionId: event.option.id,
          toastMessage:
              response['message']?.toString() ??
              'Đã ghi nhận lựa chọn của bạn.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          toastMessage: 'Mình chưa lưu được phản hồi, thử lại giúp mình nhé.',
        ),
      );
    }
  }

  void _onInterventionPromptResolved(
    InterventionPromptResolved event,
    Emitter<InterventionState> emit,
  ) {
    final nextMode = event.chooseRecovery
        ? InterventionMode.recovery
        : InterventionMode.academic;

    final nextRestSeconds = event.chooseRecovery
        ? (state.remainingRestSeconds > 0
              ? state.remainingRestSeconds
              : _defaultRecoverySeconds)
        : state.remainingRestSeconds;

    emit(
      state.copyWith(
        mode: nextMode,
        remainingRestSeconds: nextRestSeconds,
        showUncertaintyPrompt: false,
        toastMessage: event.chooseRecovery
            ? 'Mình để bạn nghỉ một chút nhé.'
            : 'Okie, mình đưa gợi ý học nhẹ nhàng luôn nè.',
      ),
    );

    _inspectionRuntimeStore.addDecision(
      action: event.chooseRecovery
          ? 'HITL Confirmed Recovery'
          : 'HITL Continue Guidance',
      reason: event.chooseRecovery
          ? 'Người dùng chọn nghỉ để phục hồi trước khi học tiếp.'
          : 'Người dùng muốn nhận gợi ý học ngay, không nghỉ.',
      source: 'hitl',
    );

    _inspectionRuntimeStore.updateMentalState(
      label: nextMode == InterventionMode.recovery ? 'Hơi mệt' : 'Tập trung',
      hint: nextMode == InterventionMode.recovery
          ? 'Đang ở Recovery Mode để nạp lại năng lượng.'
          : 'Đã xác nhận học tiếp, ưu tiên gợi ý ngắn gọn.',
    );

    _syncRecoveryTimer(nextMode, nextRestSeconds);
  }

  void _onInterventionMessageCleared(
    InterventionMessageCleared event,
    Emitter<InterventionState> emit,
  ) {
    emit(state.copyWith(toastMessage: null));
  }

  void _onRecoveryTicked(
    RecoveryTicked event,
    Emitter<InterventionState> emit,
  ) {
    if (state.mode != InterventionMode.recovery) {
      _stopRecoveryTimer();
      return;
    }

    if (state.remainingRestSeconds <= 0) {
      _stopRecoveryTimer();
      return;
    }

    final nextValue = state.remainingRestSeconds - 1;
    emit(state.copyWith(remainingRestSeconds: nextValue));

    if (nextValue <= 0) {
      _stopRecoveryTimer();
      emit(
        state.copyWith(
          toastMessage: 'Bạn nghỉ đủ rồi, mình quay lại học nhẹ nhàng nha.',
        ),
      );
    }
  }

  List<InterventionOption> _buildOptionsFromBackend(
    List<Map<String, dynamic>> backendPlan,
  ) {
    final mapped = backendPlan
        .map((item) {
          final id = item['id']?.toString() ?? '';
          final title = item['title']?.toString() ?? '';
          final type = item['type']?.toString() ?? 'general';
          if (id.isEmpty || title.isEmpty) {
            return null;
          }

          return InterventionOption(
            id: id,
            label: title,
            type: type,
            fromBackend: true,
          );
        })
        .whereType<InterventionOption>()
        .toList();

    if (mapped.isEmpty) {
      return const <InterventionOption>[
        InterventionOption(
          id: 'review_theory',
          label: 'Ôn lại lý thuyết mượt mà',
          type: 'academic',
        ),
        InterventionOption(
          id: 'easier_practice',
          label: 'Làm bài dễ hơn chút nè',
          type: 'academic',
        ),
        InterventionOption(
          id: 'skip_once',
          label: 'Bỏ qua lần này cũng không sao',
          type: 'recovery',
        ),
      ];
    }

    final withSkip = <InterventionOption>[...mapped];
    if (!withSkip.any((option) => option.id == 'skip_once')) {
      withSkip.add(
        const InterventionOption(
          id: 'skip_once',
          label: 'Bỏ qua lần này cũng không sao',
          type: 'recovery',
        ),
      );
    }

    return withSkip;
  }

  void _syncRecoveryTimer(InterventionMode mode, int remainingSeconds) {
    if (mode == InterventionMode.recovery && remainingSeconds > 0) {
      _startRecoveryTimer();
    } else {
      _stopRecoveryTimer();
    }
  }

  void _startRecoveryTimer() {
    if (_recoveryTimer?.isActive == true) {
      return;
    }

    _recoveryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const RecoveryTicked());
    });
  }

  void _stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  @override
  Future<void> close() {
    _stopRecoveryTimer();
    return super.close();
  }
}
