import 'package:json_annotation/json_annotation.dart';

part 'auth_tokens.g.dart';

/// Response khi login/register thành công.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AuthTokenResponse {
  const AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final UserInfo? user;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenResponseToJson(this);

  /// Thời điểm token hết hạn (tính từ thời điểm nhận)
  DateTime get expiresAt {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Check nếu token sắp hết hạn (còn dưới 5 phút)
  bool get isExpiringSoon {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.inMinutes < 5;
  }
}

/// Thông tin user từ auth response
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserInfo {
  const UserInfo({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'student',
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? createdAt;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  /// Tên hiển thị mặc định nếu không có
  String get safeDisplayName => displayName ?? email.split('@').first;
}
