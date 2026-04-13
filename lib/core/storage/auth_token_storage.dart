import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_tokens.dart';
import '../network/api_config.dart';

/// Quản lý việc lưu trữ và truy xuất auth tokens.
///
/// Dùng [FlutterSecureStorage] để mã hóa tokens:
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
/// - Web: localStorage (không mã hóa, cẩn thận!)
class AuthTokenStorage {
  AuthTokenStorage({FlutterSecureStorage? secureStorage})
    : _storage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  /// Lưu token response từ login/register/refresh.
  /// Trên Web, skip vì secure storage không hỗ trợ.
  Future<void> saveTokens(AuthTokenResponse tokens) async {
    if (kIsWeb) {
      debugPrint(
        '⚠️ Web: Skipping token storage (secure storage not supported)',
      );
      return;
    }

    try {
      await _storage.write(
        key: ApiConfig.accessTokenStorageKey,
        value: tokens.accessToken,
      );
      await _storage.write(
        key: ApiConfig.refreshTokenStorageKey,
        value: tokens.refreshToken,
      );
      await _storage.write(
        key: ApiConfig.tokenExpiryStorageKey,
        value: tokens.expiresAt.toIso8601String(),
      );

      debugPrint('✅ Auth tokens saved for user: ${tokens.user?.email}');
    } catch (e) {
      debugPrint('❌ Lỗi lưu auth tokens: $e');
      rethrow;
    }
  }

  /// Lấy access token hiện tại.
  /// Trên Web, luôn trả về null.
  Future<String?> getAccessToken() async {
    if (kIsWeb) return null;

    try {
      return _storage.read(key: ApiConfig.accessTokenStorageKey);
    } catch (e) {
      debugPrint('❌ Lỗi đọc access token: $e');
      return null;
    }
  }

  /// Lấy refresh token hiện tại.
  /// Trên Web, luôn trả về null.
  Future<String?> getRefreshToken() async {
    if (kIsWeb) return null;

    try {
      return _storage.read(key: ApiConfig.refreshTokenStorageKey);
    } catch (e) {
      debugPrint('❌ Lỗi đọc refresh token: $e');
      return null;
    }
  }

  /// Kiểm tra xem access token có còn hạn không.
  /// Trên Web, luôn trả về false.
  Future<bool> isAccessTokenValid() async {
    if (kIsWeb) return false;

    try {
      final expiryStr = await _storage.read(
        key: ApiConfig.tokenExpiryStorageKey,
      );
      if (expiryStr == null || expiryStr.isEmpty) {
        return false;
      }

      final expiryTime = DateTime.parse(expiryStr);
      // Thêm buffer 1 phút để tránh race condition
      return expiryTime.isAfter(DateTime.now().add(const Duration(minutes: 1)));
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra token expiry: $e');
      return false;
    }
  }

  /// Xóa toàn bộ tokens (dùng khi logout).
  /// Trên Web, skip vì secure storage không hỗ trợ.
  Future<void> clearTokens() async {
    if (kIsWeb) return;

    try {
      await _storage.delete(key: ApiConfig.accessTokenStorageKey);
      await _storage.delete(key: ApiConfig.refreshTokenStorageKey);
      await _storage.delete(key: ApiConfig.tokenExpiryStorageKey);

      debugPrint('🗑️ Auth tokens cleared');
    } catch (e) {
      debugPrint('❌ Lỗi xóa auth tokens: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem đã có tokens trong storage chưa.
  /// Trên Web, luôn trả về false.
  Future<bool> hasTokens() async {
    if (kIsWeb) return false;

    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}

/// Singleton để dùng toàn app.
class GlobalTokenStorage {
  GlobalTokenStorage._();

  static final AuthTokenStorage instance = AuthTokenStorage();
}
