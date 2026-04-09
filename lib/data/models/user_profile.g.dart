// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  fullName: json['full_name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  avatarUrl: json['avatar_url'] as String?,
  gradeLevel: json['grade_level'] as String?,
  activeSubjects:
      (json['active_subjects'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  learningPreferences:
      json['learning_preferences'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  recoveryModeEnabled: json['recovery_mode_enabled'] as bool? ?? false,
  consentBehavioral: json['consent_behavioral'] as bool? ?? false,
  consentAnalytics: json['consent_analytics'] as bool? ?? false,
  subscriptionTier: json['subscription_tier'] as String? ?? 'free',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  lastActive: json['last_active'] == null
      ? null
      : DateTime.parse(json['last_active'] as String),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'grade_level': instance.gradeLevel,
      'active_subjects': instance.activeSubjects,
      'learning_preferences': instance.learningPreferences,
      'recovery_mode_enabled': instance.recoveryModeEnabled,
      'consent_behavioral': instance.consentBehavioral,
      'consent_analytics': instance.consentAnalytics,
      'subscription_tier': instance.subscriptionTier,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'last_active': instance.lastActive?.toIso8601String(),
    };
