import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'full_name') @Default('') String fullName,
    @JsonKey(name: 'email') @Default('') String email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'grade_level') String? gradeLevel,
    @JsonKey(name: 'active_subjects')
    @Default(<String>[])
    List<String> activeSubjects,
    // Agentic feature: RL Strategy Policy reads this JSONB to personalize pathing.
    @JsonKey(name: 'learning_preferences')
    @Default(<String, dynamic>{})
    Map<String, dynamic> learningPreferences,
    // Agentic feature: enables gentle intervention branch when learner is overloaded.
    @JsonKey(name: 'recovery_mode_enabled')
    @Default(false)
    bool recoveryModeEnabled,
    @JsonKey(name: 'consent_behavioral') @Default(false) bool consentBehavioral,
    @JsonKey(name: 'consent_analytics') @Default(false) bool consentAnalytics,
    @JsonKey(name: 'subscription_tier')
    @Default('free')
    String subscriptionTier,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_active') DateTime? lastActive,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  bool get shouldCollectBehavioralSignals => consentBehavioral;

  Map<String, dynamic> toUpsertJson() {
    final json = toJson();

    // Timestamps are server-managed in normal updates.
    if (createdAt == null) {
      json.remove('created_at');
    }
    if (updatedAt == null) {
      json.remove('updated_at');
    }
    if (lastActive == null) {
      json.remove('last_active');
    }

    return json;
  }
}
