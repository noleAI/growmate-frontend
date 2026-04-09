import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.email,
    required this.displayName,
  });

  final String token;
  final String email;
  final String displayName;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

class AuthRepository {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _nameKey = 'auth_name';
  static const String _passwordResetRedirectTo = String.fromEnvironment(
    'SUPABASE_PASSWORD_RESET_REDIRECT_TO',
  );

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  AuthRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient();

  final SupabaseClient? _supabaseClient;

  Future<AuthSession?> restoreSession() async {
    final client = _supabaseClient;
    if (client != null) {
      final currentSession = client.auth.currentSession;
      if (currentSession == null) {
        return null;
      }

      return _sessionFromSupabase(
        session: currentSession,
        user: client.auth.currentUser,
      );
    }

    return _restoreMockSession();
  }

  Future<AuthSession?> _restoreMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    final email = prefs.getString(_emailKey) ?? 'learner@growmate.vn';
    final displayName = prefs.getString(_nameKey) ?? 'Bạn';

    return AuthSession(token: token, email: email, displayName: displayName);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw const AuthFailure(
        'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿',
      );
    }

    if (password.trim().length < 6) {
      throw const AuthFailure(
        'Mật khẩu cần ít nhất 6 ký tự để an toàn hơn nhé 🌱',
      );
    }

    final client = _supabaseClient;
    if (client != null) {
      try {
        final response = await client.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );

        final session = response.session;
        if (session == null) {
          throw const AuthFailure(
            'Bạn cần xác nhận email trước khi đăng nhập nhé ✨',
          );
        }

        return _sessionFromSupabase(session: session, user: response.user);
      } on AuthException catch (error) {
        throw AuthFailure(_mapSupabaseError(error.message));
      } on AuthFailure {
        rethrow;
      } catch (_) {
        throw const AuthFailure(
          'Kết nối hơi chậm một chút, mình thử lại ngay nhé 🌿',
        );
      }
    }

    return _loginWithMock(normalizedEmail: normalizedEmail);
  }

  Future<AuthSession> _loginWithMock({required String normalizedEmail}) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    final inferredName = normalizedEmail.split('@').first;
    final displayName = _toDisplayName(inferredName);

    final session = AuthSession(
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName,
    );

    await _persistSession(session);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final displayName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (displayName.isEmpty) {
      throw const AuthFailure('Bạn thêm tên để mình xưng hô dễ hơn nha 🌿');
    }

    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw const AuthFailure(
        'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿',
      );
    }

    if (password.trim().length < 6) {
      throw const AuthFailure(
        'Mật khẩu cần ít nhất 6 ký tự để an toàn hơn nhé 🌱',
      );
    }

    if (password != confirmPassword) {
      throw const AuthFailure(
        'Hai mật khẩu chưa trùng nhau, mình nhập lại một chút nhé ✨',
      );
    }

    final client = _supabaseClient;
    if (client != null) {
      try {
        final response = await client.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: <String, dynamic>{'display_name': displayName},
        );

        final session = response.session;
        if (session == null) {
          throw const AuthFailure(
            'Tài khoản đã được tạo. Bạn kiểm tra email để xác nhận rồi đăng nhập nhé ✨',
          );
        }

        return _sessionFromSupabase(session: session, user: response.user);
      } on AuthException catch (error) {
        throw AuthFailure(_mapSupabaseError(error.message));
      } on AuthFailure {
        rethrow;
      } catch (_) {
        throw const AuthFailure(
          'Mình chưa tạo được tài khoản lúc này, thử lại giúp mình nhé 🌱',
        );
      }
    }

    return _registerWithMock(
      normalizedEmail: normalizedEmail,
      displayName: displayName,
    );
  }

  Future<AuthSession> _registerWithMock({
    required String normalizedEmail,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final session = AuthSession(
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName,
    );

    await _persistSession(session);
    return session;
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw const AuthFailure(
        'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿',
      );
    }

    final client = _supabaseClient;
    if (client != null) {
      try {
        if (_passwordResetRedirectTo.isEmpty) {
          await client.auth.resetPasswordForEmail(normalizedEmail);
          return;
        }

        await client.auth.resetPasswordForEmail(
          normalizedEmail,
          redirectTo: _passwordResetRedirectTo,
        );
        return;
      } on AuthException catch (error) {
        throw AuthFailure(_mapSupabaseError(error.message));
      } catch (_) {
        throw const AuthFailure(
          'Kết nối hơi chậm, mình thử lại một chút nhé 🌿',
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 850));
  }

  Future<void> logout() async {
    final client = _supabaseClient;
    if (client != null) {
      await client.auth.signOut();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  Future<void> _persistSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_nameKey, session.displayName);
  }

  AuthSession _sessionFromSupabase({
    required Session session,
    required User? user,
  }) {
    final email = user?.email?.trim().toLowerCase() ?? '';
    final displayName = _displayNameFromSupabase(user: user, email: email);

    return AuthSession(
      token: session.accessToken,
      email: email,
      displayName: displayName,
    );
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _displayNameFromSupabase({
    required User? user,
    required String email,
  }) {
    final metadataName = user?.userMetadata?['display_name']?.toString().trim();
    if (metadataName != null && metadataName.isNotEmpty) {
      return metadataName;
    }

    if (email.isEmpty) {
      return 'Bạn';
    }

    return _toDisplayName(email.split('@').first);
  }

  static String _mapSupabaseError(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu chưa đúng, bạn thử lại nhé 🌿';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Bạn cần xác nhận email trước khi đăng nhập nhé ✨';
    }

    if (normalized.contains('user already registered')) {
      return 'Email này đã có tài khoản rồi, mình đăng nhập nha 🌱';
    }

    if (normalized.contains('password should be at least')) {
      return 'Mật khẩu cần ít nhất 6 ký tự để an toàn hơn nhé 🌱';
    }

    if (normalized.contains('unable to validate email address')) {
      return 'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿';
    }

    return message;
  }

  static String _toDisplayName(String raw) {
    if (raw.isEmpty) {
      return 'Bạn';
    }

    final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').trim();
    if (sanitized.isEmpty) {
      return 'Bạn';
    }

    final words = sanitized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(3)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        });

    return words.join(' ');
  }
}
