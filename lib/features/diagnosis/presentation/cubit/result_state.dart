import 'package:equatable/equatable.dart';

class ResultModel extends Equatable {
  const ResultModel({
    required this.submissionId,
    required this.diagnosisId,
    required this.headline,
    required this.gapAnalysis,
    required this.diagnosisReason,
    required this.strengths,
    required this.needsReview,
    required this.nextSuggestedTopic,
    required this.interventionPlan,
    required this.finalMode,
    required this.confidenceScore,
    required this.uncertaintyScore,
    required this.riskLevel,
    required this.requiresHitl,
  });

  final String submissionId;
  final String diagnosisId;
  final String headline;
  final String gapAnalysis;
  final String diagnosisReason;
  final List<String> strengths;
  final List<String> needsReview;
  final String nextSuggestedTopic;
  final List<Map<String, dynamic>> interventionPlan;
  final String finalMode;
  final double confidenceScore;
  final double uncertaintyScore;
  final String riskLevel;
  final bool requiresHitl;

  ResultModel copyWith({
    String? submissionId,
    String? diagnosisId,
    String? headline,
    String? gapAnalysis,
    String? diagnosisReason,
    List<String>? strengths,
    List<String>? needsReview,
    String? nextSuggestedTopic,
    List<Map<String, dynamic>>? interventionPlan,
    String? finalMode,
    double? confidenceScore,
    double? uncertaintyScore,
    String? riskLevel,
    bool? requiresHitl,
  }) {
    return ResultModel(
      submissionId: submissionId ?? this.submissionId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      headline: headline ?? this.headline,
      gapAnalysis: gapAnalysis ?? this.gapAnalysis,
      diagnosisReason: diagnosisReason ?? this.diagnosisReason,
      strengths: strengths ?? this.strengths,
      needsReview: needsReview ?? this.needsReview,
      nextSuggestedTopic: nextSuggestedTopic ?? this.nextSuggestedTopic,
      interventionPlan: interventionPlan ?? this.interventionPlan,
      finalMode: finalMode ?? this.finalMode,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      uncertaintyScore: uncertaintyScore ?? this.uncertaintyScore,
      riskLevel: riskLevel ?? this.riskLevel,
      requiresHitl: requiresHitl ?? this.requiresHitl,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    submissionId,
    diagnosisId,
    headline,
    gapAnalysis,
    diagnosisReason,
    strengths,
    needsReview,
    nextSuggestedTopic,
    interventionPlan,
    finalMode,
    confidenceScore,
    uncertaintyScore,
    riskLevel,
    requiresHitl,
  ];
}

sealed class ResultState extends Equatable {
  const ResultState();

  @override
  List<Object?> get props => <Object?>[];
}

final class ResultLoading extends ResultState {
  const ResultLoading();
}

final class ResultFailure extends ResultState {
  const ResultFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class ResultReady extends ResultState {
  const ResultReady({
    required this.result,
    this.isAnalyzingFeedback = false,
    this.infoMessage,
    this.navigateToNextQuiz = false,
  });

  final ResultModel result;
  final bool isAnalyzingFeedback;
  final String? infoMessage;
  final bool navigateToNextQuiz;

  bool get navigateToIntervention => navigateToNextQuiz;

  ResultReady copyWith({
    ResultModel? result,
    bool? isAnalyzingFeedback,
    String? infoMessage,
    bool? navigateToNextQuiz,
    bool? navigateToIntervention,
  }) {
    final nextNavigation =
        navigateToIntervention ?? navigateToNextQuiz ?? this.navigateToNextQuiz;

    return ResultReady(
      result: result ?? this.result,
      isAnalyzingFeedback: isAnalyzingFeedback ?? this.isAnalyzingFeedback,
      infoMessage: infoMessage,
      navigateToNextQuiz: nextNavigation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    result,
    isAnalyzingFeedback,
    infoMessage,
    navigateToNextQuiz,
  ];
}
