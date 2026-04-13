// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokenResponse _$AuthTokenResponseFromJson(Map<String, dynamic> json) =>
    AuthTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: json['user'] == null
          ? null
          : UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthTokenResponseToJson(AuthTokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
      'user': instance.user?.toJson(),
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['display_name'] as String?,
  role: json['role'] as String? ?? 'student',
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'role': instance.role,
  'created_at': instance.createdAt,
};
