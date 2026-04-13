import 'dart:async' as dart_async;
import 'dart:io' as dart_io_http;

/// Exception hierarchy cho GrowMate API layer.
///
/// Tất cả exceptions trong app nên kế thừa từ [AppException]
/// để dễ dàng xử lý và phân loại lỗi.

/// Base exception cho tất cả errors trong ứng dụng.
abstract class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  /// Machine-readable error code (e.g., 'UNAUTHORIZED', 'VALIDATION_ERROR')
  final String code;

  /// Human-readable message (preferably in Vietnamese for user-facing errors)
  final String message;

  /// Additional error details (optional)
  final Map<String, dynamic>? details;

  /// HTTP status code (if applicable)
  final int? statusCode;

  @override
  String toString() {
    final buffer = StringBuffer('AppException($code)');
    if (message.isNotEmpty) {
      buffer.write(': $message');
    }
    if (statusCode != null) {
      buffer.write(' [$statusCode]');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(' | Details: $details');
    }
    return buffer.toString();
  }
}

/// Lỗi kết nối mạng (mất internet, DNS fail, v.v.)
class NetworkException extends AppException {
  const NetworkException({
    super.message =
        'Không thể kết nối mạng, vui lòng kiểm tra lại internet của bạn 🌿',
    super.details,
  }) : super(code: 'NETWORK_ERROR', statusCode: 0);
}

/// Lỗi timeout - request quá thời gian chờ
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Kết nối chậm quá mức cho phép, bạn thử lại nhé 🌱',
    super.details,
    this.duration,
  }) : super(code: 'TIMEOUT');

  final Duration? duration;
}

/// Lỗi 401 - Chưa xác thực hoặc token hết hạn
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại ✨',
    super.details,
    super.statusCode = 401,
  }) : super(code: 'UNAUTHORIZED');
}

/// Lỗi 401 - Token expired cụ thể
class TokenExpiredException extends UnauthorizedException {
  const TokenExpiredException({
    super.message = 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại ✨',
    super.details,
  });
}

/// Lỗi 403 - Không có quyền truy cập
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Bạn không có quyền thực hiện hành động này 🌿',
    super.details,
    super.statusCode = 403,
  }) : super(code: 'FORBIDDEN');
}

/// Lỗi 404 - Resource không tồn tại
class NotFoundException extends AppException {
  const NotFoundException({
    required this.resource,
    String? message,
    super.details,
    super.statusCode = 404,
  }) : super(
         code: 'NOT_FOUND',
         message: message ?? 'Không tìm thấy $resource yêu cầu 🌱',
       );

  final String resource;
}

/// Lỗi 409 - Conflict (email đã tồn tại, v.v.)
class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.details,
    super.statusCode = 409,
  }) : super(code: 'CONFLICT');
}

/// Lỗi 422 - Dữ liệu không hợp lệ về mặt logic
class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Dữ liệu không hợp lệ, vui lòng kiểm tra lại 🌿',
    super.details,
    super.statusCode = 422,
  }) : super(code: 'VALIDATION_ERROR');
}

/// Lỗi 429 - Rate limited
class RateLimitException extends AppException {
  const RateLimitException({
    super.message =
        'Bạn đã thực hiện quá nhiều lần, vui lòng chờ một chút nhé 🌱',
    super.details,
    super.statusCode = 429,
    this.retryAfter,
  }) : super(code: 'RATE_LIMITED');

  final Duration? retryAfter;
}

/// Lỗi 5xx - Server error
class ServerException extends AppException {
  const ServerException({
    super.message = 'Hệ thống đang có chút trục trặc, bạn thử lại sau nhé 🌿',
    super.details,
    super.statusCode,
  }) : super(code: 'SERVER_ERROR');
}

/// Lỗi 503 - Service unavailable
class ServiceUnavailableException extends ServerException {
  const ServiceUnavailableException({
    super.message = 'Hệ thống đang bảo trì, bạn quay lại sau nhé ✨',
    super.details,
  }) : super(statusCode: 503);
}

/// Lỗi parse response JSON
class ParseException extends AppException {
  const ParseException({
    required this.rawResponse,
    super.message = 'Dữ liệu phản hồi không hợp lệ 🌿',
    super.details,
  }) : super(code: 'PARSE_ERROR');

  final String rawResponse;
}

/// Lỗi không xác định
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'Có lỗi xảy ra, vui lòng thử lại 🌿',
    super.details,
    super.statusCode,
    this.originalError,
  }) : super(code: 'UNKNOWN');

  final Object? originalError;
}

/// Helper: chuyển HTTP status code sang AppException phù hợp
AppException exceptionFromHttpStatus(
  int statusCode,
  String body, {
  Map<String, dynamic>? parsedJson,
}) {
  final message = _extractMessage(parsedJson, body);
  final details = _extractDetails(parsedJson);

  return switch (statusCode) {
    0 => const NetworkException(),
    401 =>
      _isTokenExpired(parsedJson)
          ? const TokenExpiredException()
          : UnauthorizedException(message: message, details: details),
    403 => ForbiddenException(message: message, details: details),
    404 => NotFoundException(
      resource: 'resource',
      message: message,
      details: details,
    ),
    409 => ConflictException(message: message, details: details),
    422 => ValidationException(message: message, details: details),
    429 => RateLimitException(message: message, details: details),
    503 => const ServiceUnavailableException(),
    >= 500 => ServerException(
      message: message,
      details: details,
      statusCode: statusCode,
    ),
    _ => UnknownException(
      message: message,
      details: details,
      statusCode: statusCode,
    ),
  };
}

/// Helper: chuyển Exception bất kỳ thành AppException
AppException wrapException(Object error, {StackTrace? stackTrace}) {
  if (error is AppException) {
    return error;
  }

  if (error is dart_io_http.HttpException) {
    return const NetworkException();
  }

  if (error is dart_async.TimeoutException) {
    return TimeoutException(duration: error.duration);
  }

  if (error is FormatException) {
    return const ParseException(rawResponse: '<unknown>');
  }

  return UnknownException(originalError: error);
}

// Helper functions để parse response từ backend

String _extractMessage(Map<String, dynamic>? json, String rawBody) {
  if (json != null) {
    return json['message']?.toString() ??
        json['error']?.toString() ??
        'Có lỗi xảy ra 🌿';
  }
  return rawBody.isEmpty ? 'Có lỗi xảy ra 🌿' : rawBody;
}

Map<String, dynamic>? _extractDetails(Map<String, dynamic>? json) {
  if (json != null) {
    final details = json['details'];
    if (details is Map) {
      return Map<String, dynamic>.from(details);
    }
  }
  return null;
}

bool _isTokenExpired(Map<String, dynamic>? json) {
  if (json == null) return false;
  final code = json['code']?.toString().toLowerCase() ?? '';
  final message = json['message']?.toString().toLowerCase() ?? '';
  return code == 'token_expired' ||
      code == 'tokenexpired' ||
      message.contains('token') && message.contains('expir');
}
