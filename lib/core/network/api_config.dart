import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình API tập trung cho toàn bộ ứng dụng.
///
/// Lấy giá trị từ `.env` file hoặc fallback sang defaults.
/// Sử dụng class này thay vì hardcode URLs ở bất kỳ đâu.
class ApiConfig {
  ApiConfig._();

  // ===== Base URLs =====

  /// REST API base URL.
  /// Ví dụ: `https://api.growmate.vn/v1`
  static String get restApiBaseUrl {
    String? fromEnv;
    try {
      fromEnv = dotenv.env['API_BASE_URL']?.trim();
    } catch (_) {
      // Dotenv chưa được khởi tạo (trong tests)
    }

    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // Fallback theo môi trường
    if (kReleaseMode) {
      return 'https://api.growmate.vn/v1';
    }

    if (kProfileMode || kDebugMode) {
      // Trong development, có thể dùng local server
      return 'http://localhost:8080/api/v1';
    }

    return 'https://api-staging.growmate.vn/v1';
  }

  static String get agenticApiBaseUrl {
    String? fromEnv;
    try {
      fromEnv = dotenv.env['AGENTIC_BASE_URL']?.trim();
    } catch (_) {
      // Dotenv not initialized yet.
    }

    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    return restApiBaseUrl;
  }

  static bool get strictRealBackendDemo {
    try {
      return (dotenv.env['STRICT_REAL_BACKEND_DEMO'] ?? '')
              .trim()
              .toLowerCase() ==
          'true';
    } catch (_) {
      return false;
    }
  }

  static Uri get backendServiceBaseUri {
    final uri = Uri.parse(agenticApiBaseUrl);
    final segments = uri.pathSegments.toList(growable: true);
    if (segments.length >= 2 &&
        segments[segments.length - 2] == 'api' &&
        segments.last == 'v1') {
      segments.removeLast();
      segments.removeLast();
    }

    return uri.replace(pathSegments: segments, query: '');
  }

  static Uri get backendDocsUri => backendServiceBaseUri.replace(
    path: '${backendServiceBaseUri.path}/docs'.replaceAll('//', '/'),
  );

  static Uri get backendOpenApiUri => backendServiceBaseUri.replace(
    path: '${backendServiceBaseUri.path}/openapi.json'.replaceAll('//', '/'),
  );

  static String get agenticWsBaseUrl {
    final uri = Uri.parse(agenticApiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ws/v1';
  }

  /// Connect timeout
  static Duration get connectTimeout => const Duration(seconds: 15);

  /// Receive timeout cho đa số requests
  static Duration get receiveTimeout => const Duration(seconds: 30);

  /// Receive timeout cho các requests lâu (upload, download lớn)
  static Duration get longReceiveTimeout => const Duration(seconds: 60);

  // ===== Retry Configuration =====

  /// Số lần retry tối đa cho failed requests
  static int get maxRetries => 3;

  /// Delay ban đầu giữa các retries (sẽ tăng theo exponential backoff)
  static Duration get initialRetryDelay => const Duration(milliseconds: 500);

  /// Hệ số tăng cho retry delay (delay = initialDelay * multiplier^attempt)
  static int get retryMultiplier => 2;

  // ===== Token Configuration =====

  /// Access token TTL (giờ)
  static int get accessTokenTtlHours => 1;

  /// Refresh token TTL (ngày)
  static int get refreshTokenTtlDays => 30;

  /// Header key cho access token
  static String get authHeaderKey => 'Authorization';

  /// Prefix cho Bearer token
  static String get bearerPrefix => 'Bearer';

  // ===== Rate Limiting =====

  /// Số giây chờ trước khi retry khi bị 429 Rate Limited
  static Duration get rateLimitRetryAfter => const Duration(seconds: 60);

  /// Số requests tối đa mỗi phút cho auth endpoints
  static int get authRateLimit => 5;

  /// Số requests tối đa mỗi phút cho quiz endpoints
  static int get quizRateLimit => 30;

  // ===== Logging =====

  /// Có bật logging cho HTTP requests không?
  /// Chỉ nên bật trong development
  static bool get enableHttpLogging => kDebugMode;

  /// Có log request/response body không?
  /// Thận trọng vì có thể lộ sensitive data
  static bool get logResponseBody => kDebugMode && false; // default off

  // ===== Session Management =====

  /// Key để lưu session ID trong secure storage
  static String get sessionIdStorageKey => 'learning_session_id';

  /// Key để lưu access token
  static String get accessTokenStorageKey => 'access_token';

  /// Key để lưu refresh token
  static String get refreshTokenStorageKey => 'refresh_token';

  /// Key để lưu token expiry time
  static String get tokenExpiryStorageKey => 'token_expiry_time';

  // ===== Environment Info =====

  /// Có phải production environment không?
  static bool get isProduction => kReleaseMode;

  /// Có phải development environment không?
  static bool get isDevelopment => kDebugMode;

  /// Debug info về cấu hình hiện tại
  static String get debugInfo {
    return '''
ApiConfig:
  REST API Base: $restApiBaseUrl
  Agentic API Base: $agenticApiBaseUrl
  Connect Timeout: ${connectTimeout.inSeconds}s
  Receive Timeout: ${receiveTimeout.inSeconds}s
  Max Retries: $maxRetries
  HTTP Logging: $enableHttpLogging
  Strict Demo: $strictRealBackendDemo
  Environment: ${isProduction
        ? 'Production'
        : isDevelopment
        ? 'Development'
        : 'Profile'}
''';
  }
}
