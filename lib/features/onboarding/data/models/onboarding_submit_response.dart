import '../models/user_level.dart';

/// Response model for POST /api/v1/onboarding/submit.
class OnboardingSubmitResponse {
  const OnboardingSubmitResponse({
    required this.userLevel,
    required this.accuracyPercent,
    required this.message,
    this.studyPlan,
    this.onboardingSummary,
  });

  final UserLevel userLevel;
  final double accuracyPercent;
  final String message;
  final Map<String, dynamic>? studyPlan;
  final Map<String, dynamic>? onboardingSummary;

  factory OnboardingSubmitResponse.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['user_level'] ?? 'beginner').toString();
    final level = UserLevel.values.firstWhere(
      (e) => e.name == levelStr,
      orElse: () => UserLevel.beginner,
    );
    return OnboardingSubmitResponse(
      userLevel: level,
      accuracyPercent: (json['accuracy_percent'] as num?)?.toDouble() ?? 0.0,
      message: (json['message'] ?? '').toString(),
      studyPlan: json['study_plan'] is Map
          ? Map<String, dynamic>.from(json['study_plan'] as Map)
          : null,
      onboardingSummary: json['onboarding_summary'] is Map
          ? Map<String, dynamic>.from(json['onboarding_summary'] as Map)
          : null,
    );
  }
}
