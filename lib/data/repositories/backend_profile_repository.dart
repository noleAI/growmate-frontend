import '../../../core/network/rest_api_client.dart';

/// Backend-managed profile fields from the `user_profiles` table.
///
/// Separate from the Supabase-direct `profiles` table used by
/// [ProfileRepository]. This covers fields set during onboarding
/// and managed by the backend (user_level, study_goal, daily_minutes).
class BackendUserProfile {
  const BackendUserProfile({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.userLevel,
    this.studyGoal,
    required this.dailyMinutes,
    this.onboardedAt,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String userLevel;
  final String? studyGoal;
  final int dailyMinutes;
  final DateTime? onboardedAt;

  factory BackendUserProfile.fromJson(Map<String, dynamic> json) {
    return BackendUserProfile(
      userId: (json['user_id'] ?? '').toString(),
      displayName: json['display_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      userLevel: (json['user_level'] ?? 'beginner').toString(),
      studyGoal: json['study_goal']?.toString(),
      dailyMinutes: (json['daily_minutes'] as num?)?.toInt() ?? 15,
      onboardedAt: json['onboarded_at'] != null
          ? DateTime.tryParse(json['onboarded_at'].toString())
          : null,
    );
  }
}

/// Repository for backend-managed user profile (GET/PUT /user/profile).
class BackendProfileRepository {
  BackendProfileRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  /// Fetch backend profile (user_level, study_goal, daily_minutes, etc.)
  Future<BackendUserProfile> fetchProfile() async {
    final json = await _client.get('/user/profile');
    return BackendUserProfile.fromJson(json);
  }

  /// Update mutable backend profile fields.
  Future<BackendUserProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? studyGoal,
    int? dailyMinutes,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (studyGoal != null) body['study_goal'] = studyGoal;
    if (dailyMinutes != null) body['daily_minutes'] = dailyMinutes;

    final json = await _client.put('/user/profile', body);
    return BackendUserProfile.fromJson(json);
  }
}
