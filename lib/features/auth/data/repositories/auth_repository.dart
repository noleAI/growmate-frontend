import 'package:shared_preferences/shared_preferences.dart';

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

  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  Future<AuthSession?> restoreSession() async {
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
    await Future<void>.delayed(const Duration(milliseconds: 850));

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
    await Future<void>.delayed(const Duration(milliseconds: 900));

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

    final session = AuthSession(
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName,
    );

    await _persistSession(session);
    return session;
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw const AuthFailure(
        'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿',
      );
    }
  }

  Future<void> logout() async {
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
