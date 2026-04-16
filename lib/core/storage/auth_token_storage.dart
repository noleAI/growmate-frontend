import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_tokens.dart';
import '../network/api_config.dart';

/// Quản lý việc lưu trữ và truy xuất auth tokens.
///
/// Dùng [FlutterSecureStorage] để mã hóa tokens:
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
/// - Web: localStorage (không mã hóa, cẩn thận!)
class AuthTokenStorage {
  static const String authTokenKey = 'auth_token';
  static const String authEmailKey = 'auth_email';
  static const String authNameKey = 'auth_name';

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

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Lưu token response từ login/register/refresh.
  /// Trên Web, skip vì secure storage không hỗ trợ.
  Future<void> saveTokens(AuthTokenResponse tokens) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(
        ApiConfig.accessTokenStorageKey,
        tokens.accessToken,
      );
      await prefs.setString(
        ApiConfig.refreshTokenStorageKey,
        tokens.refreshToken,
      );
      await prefs.setString(
        ApiConfig.tokenExpiryStorageKey,
        tokens.expiresAt.toIso8601String(),
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

  /// Lưu trực tiếp access/refresh token với TTL mặc định 1 giờ.
  Future<void> saveRawTokens({
    required String accessToken,
    required String refreshToken,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final expiresAt = DateTime.now().add(ttl);

    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(ApiConfig.accessTokenStorageKey, accessToken);
      await prefs.setString(ApiConfig.refreshTokenStorageKey, refreshToken);
      await prefs.setString(
        ApiConfig.tokenExpiryStorageKey,
        expiresAt.toIso8601String(),
      );
      return;
    }

    await _storage.write(
      key: ApiConfig.accessTokenStorageKey,
      value: accessToken,
    );
    await _storage.write(
      key: ApiConfig.refreshTokenStorageKey,
      value: refreshToken,
    );
    await _storage.write(
      key: ApiConfig.tokenExpiryStorageKey,
      value: expiresAt.toIso8601String(),
    );
  }

  /// Lấy access token hiện tại.
  /// Trên Web, luôn trả về null.
  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final stored = prefs.getString(ApiConfig.accessTokenStorageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      // Fallback: nếu không có token cache local, dùng session token từ Supabase.
      try {
        return Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        return null;
      }
    }

    try {
      final stored = await _storage.read(key: ApiConfig.accessTokenStorageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      try {
        return Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi đọc access token: $e');
      try {
        return Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        return null;
      }
    }
  }

  /// Lấy refresh token hiện tại.
  /// Trên Web, luôn trả về null.
  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final stored = prefs.getString(ApiConfig.refreshTokenStorageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      try {
        return Supabase.instance.client.auth.currentSession?.refreshToken;
      } catch (_) {
        return null;
      }
    }

    try {
      final stored = await _storage.read(key: ApiConfig.refreshTokenStorageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      try {
        return Supabase.instance.client.auth.currentSession?.refreshToken;
      } catch (_) {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi đọc refresh token: $e');
      try {
        return Supabase.instance.client.auth.currentSession?.refreshToken;
      } catch (_) {
        return null;
      }
    }
  }

  /// Kiểm tra xem access token có còn hạn không.
  /// Trên Web, luôn trả về false.
  Future<bool> isAccessTokenValid() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final expiryStr = prefs.getString(ApiConfig.tokenExpiryStorageKey);
      if (expiryStr == null || expiryStr.isEmpty) {
        // Khi chưa có expiry local, fallback theo session hiện tại.
        try {
          return Supabase.instance.client.auth.currentSession != null;
        } catch (_) {
          return false;
        }
      }

      final expiryTime = DateTime.parse(expiryStr);
      return expiryTime.isAfter(DateTime.now().add(const Duration(minutes: 1)));
    }

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
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(ApiConfig.accessTokenStorageKey);
      await prefs.remove(ApiConfig.refreshTokenStorageKey);
      await prefs.remove(ApiConfig.tokenExpiryStorageKey);
      return;
    }

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

  /// Lưu phiên auth cơ bản cho flow app-level.
  Future<void> saveAuthSession({
    required String token,
    required String email,
    required String displayName,
  }) async {
    if (kIsWeb) return;

    try {
      await _storage.write(key: authTokenKey, value: token);
      await _storage.write(key: authEmailKey, value: email);
      await _storage.write(key: authNameKey, value: displayName);
    } catch (e) {
      debugPrint('❌ Lỗi lưu auth session: $e');
      rethrow;
    }
  }

  /// Đọc phiên auth cơ bản.
  Future<Map<String, String>?> readAuthSession() async {
    if (kIsWeb) return null;

    try {
      final token = await _storage.read(key: authTokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }

      return <String, String>{
        'token': token,
        'email': await _storage.read(key: authEmailKey) ?? '',
        'displayName': await _storage.read(key: authNameKey) ?? '',
      };
    } catch (e) {
      debugPrint('❌ Lỗi đọc auth session: $e');
      return null;
    }
  }

  /// Xóa phiên auth cơ bản.
  Future<void> clearAuthSession() async {
    if (kIsWeb) return;

    try {
      await _storage.delete(key: authTokenKey);
      await _storage.delete(key: authEmailKey);
      await _storage.delete(key: authNameKey);
    } catch (e) {
      debugPrint('❌ Lỗi xóa auth session: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem đã có tokens trong storage chưa.
  /// Trên Web, luôn trả về false.
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}

/// Singleton để dùng toàn app.
class GlobalTokenStorage {
  GlobalTokenStorage._();

  static final AuthTokenStorage instance = AuthTokenStorage();
}
