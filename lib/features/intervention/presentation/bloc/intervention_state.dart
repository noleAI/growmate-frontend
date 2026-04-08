import 'package:equatable/equatable.dart';

enum InterventionMode { academic, recovery }

class InterventionOption extends Equatable {
  const InterventionOption({
    required this.id,
    required this.label,
    required this.type,
    this.fromBackend = false,
  });

  final String id;
  final String label;
  final String type;
  final bool fromBackend;

  @override
  List<Object?> get props => <Object?>[id, label, type, fromBackend];
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
  });

  final InterventionMode mode;
  final List<InterventionOption> options;
  final int remainingRestSeconds;
  final bool isSubmitting;
  final bool showUncertaintyPrompt;
  final bool feedbackRecorded;
  final String? toastMessage;
  final Map<String, dynamic> updatedQValues;

  InterventionState copyWith({
    InterventionMode? mode,
    List<InterventionOption>? options,
    int? remainingRestSeconds,
    bool? isSubmitting,
    bool? showUncertaintyPrompt,
    bool? feedbackRecorded,
    String? toastMessage,
    Map<String, dynamic>? updatedQValues,
  }) {
    return InterventionState(
      mode: mode ?? this.mode,
      options: options ?? this.options,
      remainingRestSeconds: remainingRestSeconds ?? this.remainingRestSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showUncertaintyPrompt: showUncertaintyPrompt ?? this.showUncertaintyPrompt,
      feedbackRecorded: feedbackRecorded ?? this.feedbackRecorded,
      toastMessage: toastMessage,
      updatedQValues: updatedQValues ?? this.updatedQValues,
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
      ];
}
