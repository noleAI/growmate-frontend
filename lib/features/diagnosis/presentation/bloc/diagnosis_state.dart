import 'package:equatable/equatable.dart';

sealed class DiagnosisState extends Equatable {
  const DiagnosisState();

  @override
  List<Object?> get props => <Object?>[];
}

final class DiagnosisLoading extends DiagnosisState {
  const DiagnosisLoading();
}

final class DiagnosisSuccess extends DiagnosisState {
  const DiagnosisSuccess({
    required this.submissionId,
    required this.diagnosisId,
    required this.headline,
    required this.gapAnalysis,
    required this.strengths,
    required this.needsReview,
    required this.diagnosisReason,
    required this.interventionPlan,
    required this.finalMode,
    required this.requiresHitl,
    this.isConfirming = false,
    this.hitlConfirmed = false,
    this.infoMessage,
  });

  final String submissionId;
  final String diagnosisId;
  final String headline;
  final String gapAnalysis;
  final List<String> strengths;
  final List<String> needsReview;
  final String diagnosisReason;
  final List<Map<String, dynamic>> interventionPlan;
  final String finalMode;
  final bool requiresHitl;
  final bool isConfirming;
  final bool hitlConfirmed;
  final String? infoMessage;

  DiagnosisSuccess copyWith({
    String? submissionId,
    String? diagnosisId,
    String? headline,
    String? gapAnalysis,
    List<String>? strengths,
    List<String>? needsReview,
    String? diagnosisReason,
    List<Map<String, dynamic>>? interventionPlan,
    String? finalMode,
    bool? requiresHitl,
    bool? isConfirming,
    bool? hitlConfirmed,
    String? infoMessage,
  }) {
    return DiagnosisSuccess(
      submissionId: submissionId ?? this.submissionId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      headline: headline ?? this.headline,
      gapAnalysis: gapAnalysis ?? this.gapAnalysis,
      strengths: strengths ?? this.strengths,
      needsReview: needsReview ?? this.needsReview,
      diagnosisReason: diagnosisReason ?? this.diagnosisReason,
      interventionPlan: interventionPlan ?? this.interventionPlan,
      finalMode: finalMode ?? this.finalMode,
      requiresHitl: requiresHitl ?? this.requiresHitl,
      isConfirming: isConfirming ?? this.isConfirming,
      hitlConfirmed: hitlConfirmed ?? this.hitlConfirmed,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    submissionId,
    diagnosisId,
    headline,
    gapAnalysis,
    strengths,
    needsReview,
    diagnosisReason,
    interventionPlan,
    finalMode,
    requiresHitl,
    isConfirming,
    hitlConfirmed,
    infoMessage,
  ];
}

final class DiagnosisFailure extends DiagnosisState {
  const DiagnosisFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
