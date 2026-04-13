import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_config.dart';

/// Quản lý learning session lifecycle cho người dùng.
///
/// Session được tạo khi user bắt đầu học và đóng khi hoàn thành.
/// Integration với:
/// - Supabase: `start_learning_session()` RPC
/// - REST API: `POST /sessions/start`
///
/// Lưu ý: FlutterSecureStorage không hỗ trợ Web, nên trên web chỉ dùng in-memory cache.
class LearningSessionManager {
  LearningSessionManager({
    FlutterSecureStorage? secureStorage,
    SupabaseClient? supabaseClient,
  }) : _storage = secureStorage ?? _defaultSecureStorage,
       _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient();

  static const FlutterSecureStorage _defaultSecureStorage =
      FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  final FlutterSecureStorage _storage;
  final SupabaseClient? _supabaseClient;
  static const String _sessionCreatedAtStorageKey = 'session_created_at';

  String? _cachedSessionId;
  DateTime? _sessionCreatedAt;

  /// Session ID hiện tại. Nếu chưa có, sẽ tạo mới.
  Future<String> getActiveSessionId() async {
    // Trả về cached session nếu còn hợp lệ (cùng user, chưa quá cũ)
    if (_cachedSessionId != null && _sessionCreatedAt != null) {
      final age = DateTime.now().difference(_sessionCreatedAt!);
      if (age < const Duration(hours: 2)) {
        return _cachedSessionId!;
      }
    }

    // Thử lấy từ storage
    final storedSession = await _loadSessionFromStorage();
    if (storedSession != null) {
      _cachedSessionId = storedSession;
      _sessionCreatedAt = DateTime.now();
      return storedSession;
    }

    // Tạo session mới
    return _createNewSession();
  }

  /// Tạo learning session mới.
  Future<String> _createNewSession() async {
    try {
      // Ưu tiên dùng Supabase RPC
      if (_supabaseClient != null) {
        final sessionId = await _createSessionViaSupabase();
        if (sessionId.isNotEmpty) {
          await _saveSessionToStorage(sessionId);
          return sessionId;
        }
      }

      // Fallback: generate local session ID
      final localSessionId = _createLocalSession();
      await _saveSessionToStorage(localSessionId);
      return localSessionId;
    } catch (e) {
      debugPrint('⚠️ Lỗi khi tạo session: $e');
      final localSessionId = _createLocalSession();
      await _saveSessionToStorage(localSessionId);
      return localSessionId;
    }
  }

  Future<String> _createSessionViaSupabase() async {
    final client = _supabaseClient;
    if (client == null) return '';

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      // Không xem đây là lỗi: app vẫn chạy bình thường với local session.
      return '';
    }

    // Gọi RPC start_learning_session
    final result = await client.rpc('start_learning_session');
    final sessionId = result?.toString() ?? '';

    if (sessionId.isNotEmpty) {
      debugPrint('✅ Tạo session thành công qua Supabase: $sessionId');
    } else {
      debugPrint('⚠️ Supabase RPC trả về session ID rỗng');
    }

    return sessionId;
  }

  String _createLocalSession() {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('📝 Tạo local session: $sessionId');
    _cachedSessionId = sessionId;
    _sessionCreatedAt = DateTime.now();
    return sessionId;
  }

  /// Đóng learning session hiện tại.
  Future<void> completeSession({String? sessionId}) async {
    final targetSessionId = sessionId ?? _cachedSessionId;
    if (targetSessionId == null) {
      return; // Không có session để đóng
    }

    try {
      final client = _supabaseClient;
      if (client != null && _isUuid(targetSessionId)) {
        await client.rpc(
          'complete_learning_session',
          params: <String, dynamic>{
            'p_session_id': targetSessionId,
            'p_status': 'completed',
          },
        );
        debugPrint('✅ Đóng session thành công: $targetSessionId');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi đóng session: $e');
    } finally {
      // Xóa cached session bất kể kết quả
      await _clearSessionFromStorage();
      _cachedSessionId = null;
      _sessionCreatedAt = null;
    }
  }

  /// Lưu session ID vào secure storage.
  /// Trên Web, skip vì secure storage không hỗ trợ.
  Future<void> _saveSessionToStorage(String sessionId) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConfig.sessionIdStorageKey, sessionId);
        await prefs.setString(
          _sessionCreatedAtStorageKey,
          DateTime.now().toIso8601String(),
        );
      } catch (e) {
        debugPrint('⚠️ Lỗi lưu session web storage: $e');
      }
      return;
    }

    try {
      await _storage.write(
        key: ApiConfig.sessionIdStorageKey,
        value: sessionId,
      );
      await _storage.write(
        key: _sessionCreatedAtStorageKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('⚠️ Lỗi lưu session vào storage: $e');
    }
  }

  /// Lấy session ID từ secure storage.
  /// Trên Web, dùng SharedPreferences để có persistence qua các lần chạy.
  Future<String?> _loadSessionFromStorage() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final sessionId = prefs.getString(ApiConfig.sessionIdStorageKey);
        final createdAtStr = prefs.getString(_sessionCreatedAtStorageKey);

        if (sessionId == null || sessionId.isEmpty) {
          return null;
        }

        if (createdAtStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr);
            final age = DateTime.now().difference(createdAt);
            if (age > const Duration(hours: 2)) {
              await _clearSessionFromStorage();
              return null;
            }
          } catch (_) {
            // Parse lỗi, coi như session hợp lệ.
          }
        }

        return sessionId;
      } catch (e) {
        debugPrint('⚠️ Lỗi đọc session web storage: $e');
        return null;
      }
    }

    try {
      final sessionId = await _storage.read(key: ApiConfig.sessionIdStorageKey);
      final createdAtStr = await _storage.read(
        key: _sessionCreatedAtStorageKey,
      );

      if (sessionId == null || sessionId.isEmpty) {
        return null;
      }

      // Kiểm tra session có quá cũ không
      if (createdAtStr != null) {
        try {
          final createdAt = DateTime.parse(createdAtStr);
          final age = DateTime.now().difference(createdAt);
          if (age > const Duration(hours: 2)) {
            // Session quá cũ, xóa đi
            await _clearSessionFromStorage();
            return null;
          }
        } catch (_) {
          // Parse lỗi, coi như session hợp lệ
        }
      }

      return sessionId;
    } catch (e) {
      debugPrint('⚠️ Lỗi đọc session từ storage: $e');
      return null;
    }
  }

  /// Xóa session khỏi secure storage.
  /// Trên Web, xóa khỏi SharedPreferences.
  Future<void> _clearSessionFromStorage() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(ApiConfig.sessionIdStorageKey);
        await prefs.remove(_sessionCreatedAtStorageKey);
      } catch (e) {
        debugPrint('⚠️ Lỗi xóa session web storage: $e');
      }
      return;
    }

    try {
      await _storage.delete(key: ApiConfig.sessionIdStorageKey);
      await _storage.delete(key: _sessionCreatedAtStorageKey);
    } catch (e) {
      debugPrint('⚠️ Lỗi xóa session khỏi storage: $e');
    }
  }

  /// Reset session manager (dùng khi logout).
  Future<void> reset() async {
    await completeSession();
    _cachedSessionId = null;
    _sessionCreatedAt = null;
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

/// Singleton instance để dùng toàn app.
class SessionManager {
  SessionManager._();

  static final LearningSessionManager instance = LearningSessionManager();
}
