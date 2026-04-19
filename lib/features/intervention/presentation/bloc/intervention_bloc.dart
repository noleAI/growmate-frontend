import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/backend_text.dart';
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
    required this.isEnglish,
    this.nextSuggestedTopic,
    this.diagnosisConfidenceScore,
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
  final bool isEnglish;
  final String? nextSuggestedTopic;
  final double? diagnosisConfidenceScore;
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
    final options = _buildOptionsFromBackend(
      backendPlan: _backendInterventionPlan,
      mode: initialMode,
    );

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

      final feedbackResponse = await _interventionRepository.submitFeedback(
        submissionId: submissionId,
        diagnosisId: diagnosisId,
        optionId: event.option.id,
        optionLabel: event.option.label,
        mode: modeLabel,
        remainingRestSeconds: state.remainingRestSeconds,
        skipped: event.option.id == 'skip_once',
      );

      final qValues = feedbackResponse.updatedQValues;
      const String? backendMessage = null;
      final completionTopic = _firstNonEmpty(<String?>[
        feedbackResponse.topic,
        nextSuggestedTopic,
        _readStringFromMap(event.option.metadata, const <String>['topic']),
        event.option.label,
      ]);
      final completionNextAction = _firstNonEmpty(<String?>[
        feedbackResponse.nextAction,
        _readStringFromMap(event.option.metadata, const <String>[
          'nextAction',
          'next_action',
        ]),
        event.option.label,
      ]);
      final completionDurationMinutes =
          feedbackResponse.durationMinutes ??
          _readIntFromMap(event.option.metadata, const <String>[
            'durationMinutes',
            'duration_minutes',
          ]);
      final completionFocusScore =
          _normalizeFocusScore(feedbackResponse.focusScore) ??
          _confidenceToFocusScore(diagnosisConfidenceScore);
      final completionConfidence =
          _normalizeUnitScore(feedbackResponse.confidenceScore) ??
          _normalizeUnitScore(diagnosisConfidenceScore);

      _inspectionRuntimeStore.updateQValues(qValues);
      _inspectionRuntimeStore.addDecision(
        action: 'Intervention Selected: ${event.option.label}',
        reason:
            backendMessage ??
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
          completionTopic: completionTopic,
          completionNextAction: completionNextAction,
          completionDurationMinutes: completionDurationMinutes,
          completionFocusScore: completionFocusScore,
          completionConfidenceScore: completionConfidence,
          toastMessage: _selectionToastMessage(
            option: event.option,
            backendMessage: backendMessage,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          toastMessage: isEnglish
              ? 'Unable to save feedback. Please try again.'
              : 'Mình chưa lưu được phản hồi, thử lại giúp mình nhé.',
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
            ? (isEnglish
                  ? 'Take a short break first.'
                  : 'Mình để bạn nghỉ một chút nhé.')
            : (isEnglish
                  ? 'Got it. Let\'s continue with gentle guidance.'
                  : 'Okie, mình đưa gợi ý học nhẹ nhàng luôn nè.'),
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
          toastMessage: isEnglish
              ? 'Break complete. Let\'s return to a gentle learning flow.'
              : 'Bạn nghỉ đủ rồi, mình quay lại học nhẹ nhàng nha.',
        ),
      );
    }
  }

  List<InterventionOption> _buildOptionsFromBackend({
    required List<Map<String, dynamic>> backendPlan,
    required InterventionMode mode,
  }) {
    final mapped = backendPlan
        .map((item) {
          final metadata = Map<String, dynamic>.from(item);
          final id = repairAndCollapseText(
            item['id']?.toString() ?? item['interventionId']?.toString() ?? '',
          );
          final title = repairAndCollapseText(item['title']?.toString() ?? '');
          final type = item['type']?.toString() ?? 'general';
          if (id.isEmpty || title.isEmpty) {
            return null;
          }

          return InterventionOption(
            id: id,
            label: _resolveOptionLabel(id: id, title: title, type: type),
            type: type,
            fromBackend: true,
            metadata: metadata,
          );
        })
        .whereType<InterventionOption>()
        .toList(growable: false);

    if (mapped.isEmpty) {
      _inspectionRuntimeStore.addDecision(
        action: 'Intervention Options Fallback',
        reason:
            'Backend returned no usable intervention options. Switching to a safe local fallback.',
        source: 'intervention',
      );

      return _buildLocalFallbackOptions(mode);
    }

    return mapped;
  }

  List<InterventionOption> _buildLocalFallbackOptions(InterventionMode mode) {
    if (mode == InterventionMode.recovery) {
      return <InterventionOption>[
        InterventionOption(
          id: 'local_recovery_break',
          label: isEnglish
              ? 'Take a short recovery break'
              : 'Nghỉ ngắn để lấy lại nhịp học',
          type: 'recovery',
          metadata: <String, dynamic>{
            'topic': nextSuggestedTopic ?? 'derivative',
            'nextAction': isEnglish
                ? 'Resume with one easier question'
                : 'Quay lại bằng một câu dễ hơn',
            'durationMinutes': 5,
          },
        ),
        InterventionOption(
          id: 'local_recovery_notation',
          label: isEnglish
              ? 'Check notation before continuing'
              : 'Soát lại ký hiệu trước khi làm tiếp',
          type: 'review',
          metadata: <String, dynamic>{
            'topic': nextSuggestedTopic ?? 'derivative',
            'nextAction': isEnglish
                ? 'Review one worked example'
                : 'Xem lại một ví dụ mẫu ngắn',
            'durationMinutes': 6,
          },
        ),
      ];
    }

    return <InterventionOption>[
      InterventionOption(
        id: 'local_review_rules',
        label: isEnglish
            ? 'Review core rules briefly'
            : 'Ôn nhanh quy tắc trọng tâm',
        type: 'review',
        metadata: <String, dynamic>{
          'topic': nextSuggestedTopic ?? 'derivative',
          'nextAction': isEnglish
              ? 'Revisit one key rule set'
              : 'Xem lại nhóm công thức chính',
          'durationMinutes': 8,
        },
      ),
      InterventionOption(
        id: 'local_practice_light',
        label: isEnglish
            ? 'Do a lighter practice set'
            : 'Làm bộ câu luyện tập nhẹ',
        type: 'practice',
        metadata: <String, dynamic>{
          'topic': nextSuggestedTopic ?? 'derivative',
          'nextAction': isEnglish
              ? 'Practice 3 gentler questions'
              : 'Luyện thêm 3 câu vừa sức',
          'durationMinutes': 10,
        },
      ),
    ];
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static String? _readStringFromMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static int? _readIntFromMap(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static double? _normalizeUnitScore(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  static double? _normalizeFocusScore(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 4) {
      return 4;
    }
    return value;
  }

  static double? _confidenceToFocusScore(double? confidence) {
    final normalized = _normalizeUnitScore(confidence);
    if (normalized == null) {
      return null;
    }
    return (normalized * 4).clamp(0.0, 4.0).toDouble();
  }

  String _resolveOptionLabel({
    required String id,
    required String title,
    required String type,
  }) {
    if (!isEnglish) {
      return repairAndCollapseText(title);
    }

    final lowerId = id.toLowerCase();
    final lowerType = type.toLowerCase();

    if (lowerId == 'skip_once') {
      return 'Skip this time';
    }
    if (lowerType.contains('breath') ||
        lowerType.contains('ground') ||
        lowerType.contains('recovery')) {
      return 'Take a short mindful break';
    }
    if (lowerType.contains('practice')) {
      return 'Do a lighter practice set';
    }
    if (lowerType.contains('review') || lowerType.contains('academic')) {
      return 'Review core concepts gently';
    }

    return repairAndCollapseText(title);
  }

  String _selectionToastMessage({
    required InterventionOption option,
    required String? backendMessage,
  }) {
    final normalizedBackend = backendMessage?.trim();

    if (isEnglish) {
      if (normalizedBackend != null &&
          normalizedBackend.isNotEmpty &&
          !_containsVietnameseChars(normalizedBackend)) {
        return normalizedBackend;
      }

      if (option.id.toLowerCase() == 'skip_once') {
        return 'Recorded: skip this round.';
      }
      return 'Your choice has been recorded.';
    }

    if (normalizedBackend != null &&
        normalizedBackend.isNotEmpty &&
        _containsVietnameseChars(normalizedBackend)) {
      return normalizedBackend;
    }

    final lowerId = option.id.toLowerCase();
    final lowerType = option.type.toLowerCase();

    if (lowerId == 'skip_once') {
      return 'Đã ghi nhận bỏ qua lần này.';
    }
    if (lowerType.contains('breath') ||
        lowerType.contains('ground') ||
        lowerType.contains('recovery')) {
      return 'Đã ghi nhận lựa chọn nghỉ ngắn để hồi phục.';
    }
    if (lowerType.contains('practice')) {
      return 'Đã ghi nhận lựa chọn làm bài nhẹ hơn.';
    }

    return 'Đã ghi nhận lựa chọn của bạn.';
  }

  bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
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
