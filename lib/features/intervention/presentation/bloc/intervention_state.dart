import 'package:equatable/equatable.dart';

enum InterventionMode { academic, recovery }

class InterventionOption extends Equatable {
  const InterventionOption({
    required this.id,
    required this.label,
    required this.type,
    this.fromBackend = false,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String label;
  final String type;
  final bool fromBackend;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => <Object?>[id, label, type, fromBackend, metadata];
}

class InterventionState extends Equatable {
  const InterventionState({
    required this.mode,
    required this.options,
    required this.remainingRestSeconds,
    required this.isSubmitting,
    required this.showUncertaintyPrompt,
    required this.feedbackRecorded,
    this.toastMessage,
    this.updatedQValues = const <String, dynamic>{},
    this.selectedOptionLabel,
    this.selectedOptionId,
    this.completionTopic,
    this.completionNextAction,
    this.completionDurationMinutes,
    this.completionFocusScore,
    this.completionConfidenceScore,
  });

  final InterventionMode mode;
  final List<InterventionOption> options;
  final int remainingRestSeconds;
  final bool isSubmitting;
  final bool showUncertaintyPrompt;
  final bool feedbackRecorded;
  final String? toastMessage;
  final Map<String, dynamic> updatedQValues;
  final String? selectedOptionLabel;
  final String? selectedOptionId;
  final String? completionTopic;
  final String? completionNextAction;
  final int? completionDurationMinutes;
  final double? completionFocusScore;
  final double? completionConfidenceScore;

  InterventionState copyWith({
    InterventionMode? mode,
    List<InterventionOption>? options,
    int? remainingRestSeconds,
    bool? isSubmitting,
    bool? showUncertaintyPrompt,
    bool? feedbackRecorded,
    String? toastMessage,
    Map<String, dynamic>? updatedQValues,
    String? selectedOptionLabel,
    String? selectedOptionId,
    String? completionTopic,
    String? completionNextAction,
    int? completionDurationMinutes,
    double? completionFocusScore,
    double? completionConfidenceScore,
  }) {
    return InterventionState(
      mode: mode ?? this.mode,
      options: options ?? this.options,
      remainingRestSeconds: remainingRestSeconds ?? this.remainingRestSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showUncertaintyPrompt:
          showUncertaintyPrompt ?? this.showUncertaintyPrompt,
      feedbackRecorded: feedbackRecorded ?? this.feedbackRecorded,
      toastMessage: toastMessage,
      updatedQValues: updatedQValues ?? this.updatedQValues,
      selectedOptionLabel: selectedOptionLabel ?? this.selectedOptionLabel,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      completionTopic: completionTopic ?? this.completionTopic,
      completionNextAction: completionNextAction ?? this.completionNextAction,
      completionDurationMinutes:
          completionDurationMinutes ?? this.completionDurationMinutes,
      completionFocusScore: completionFocusScore ?? this.completionFocusScore,
      completionConfidenceScore:
          completionConfidenceScore ?? this.completionConfidenceScore,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    mode,
    options,
    remainingRestSeconds,
    isSubmitting,
    showUncertaintyPrompt,
    feedbackRecorded,
    toastMessage,
    updatedQValues,
    selectedOptionLabel,
    selectedOptionId,
    completionTopic,
    completionNextAction,
    completionDurationMinutes,
    completionFocusScore,
    completionConfidenceScore,
  ];
}
