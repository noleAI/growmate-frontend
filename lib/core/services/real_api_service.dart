import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../error/app_exceptions.dart';
import '../network/api_config.dart';
import '../network/api_service.dart';

/// Production-ready REST API service.
///
/// Features:
/// - Auth header injection (Bearer token)
/// - Automatic token refresh on 401
/// - Retry with exponential backoff
/// - Timeout handling
/// - Request/response logging (debug only)
/// - Unified error handling via [AppException] hierarchy
class RealApiService implements ApiService {
  RealApiService({
    http.Client? httpClient,
    Future<String?> Function()? getAccessToken,
    Future<String?> Function()? getRefreshToken,
    Future<void> Function(String accessToken, String refreshToken)?
    onTokenRefresh,
  }) : _httpClient = httpClient ?? http.Client(),
       _getAccessToken = getAccessToken,
       _getRefreshToken = getRefreshToken,
       _onTokenRefresh = onTokenRefresh;

  final http.Client _httpClient;
  final Future<String?> Function()? _getAccessToken;
  final Future<String?> Function()? _getRefreshToken;
  final Future<void> Function(String accessToken, String refreshToken)?
  _onTokenRefresh;

  bool _isRefreshing = false;

  String get baseUrl => ApiConfig.restApiBaseUrl;

  // ===== ApiService Implementation =====

  @override
  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) {
    return _post('/quiz/submit-answer', <String, dynamic>{
      'sessionId': sessionId,
      'questionId': questionId,
      'answerText': answer,
      'context': context ?? <String, dynamic>{},
    });
  }

  @override
  Future<Map<String, dynamic>> getDiagnosis({
    required String sessionId,
    required String answerId,
  }) {
    return _post('/diagnosis/get', <String, dynamic>{
      'sessionId': sessionId,
      'answerId': answerId,
    });
  }

  @override
  Future<Map<String, dynamic>> submitSignals({
    required String sessionId,
    required List<Map<String, dynamic>> signals,
  }) {
    return _post('/signals/batch', <String, dynamic>{
      'sessionId': sessionId,
      'signals': signals,
    });
  }

  @override
  Future<Map<String, dynamic>> submitInterventionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String optionId,
    required String optionLabel,
    required String mode,
    required int remainingRestSeconds,
    bool skipped = false,
  }) {
    return _post('/intervention/feedback', <String, dynamic>{
      'sessionId': sessionId,
      'submissionId': submissionId,
      'diagnosisId': diagnosisId,
      'optionId': optionId,
      'optionLabel': optionLabel,
      'mode': mode,
      'remainingRestSeconds': remainingRestSeconds,
      'skipped': skipped,
    });
  }

  @override
  Future<Map<String, dynamic>> confirmHITL({
    required String sessionId,
    required String diagnosisId,
    required bool approved,
    String? reviewerNote,
  }) {
    return _post('/diagnosis/hitl/confirm', <String, dynamic>{
      'sessionId': sessionId,
      'diagnosisId': diagnosisId,
      'approved': approved,
      'reviewerNote': reviewerNote,
    });
  }

  @override
  Future<Map<String, dynamic>> saveInteractionFeedback({
    required String sessionId,
    required String submissionId,
    required String diagnosisId,
    required String eventName,
    required String memoryScope,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    return _post('/memory/interaction-feedback', <String, dynamic>{
      'sessionId': sessionId,
      'submissionId': submissionId,
      'diagnosisId': diagnosisId,
      'eventName': eventName,
      'memoryScope': memoryScope,
      'reason': reason,
      'metadata': metadata ?? <String, dynamic>{},
    });
  }

  // ===== Core HTTP Methods =====

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final stopwatch = Stopwatch()..start();

    try {
      if (ApiConfig.enableHttpLogging) {
        debugPrint('🌐 [REQUEST] POST $path');
        if (ApiConfig.logResponseBody) {
          debugPrint(
            '   Body: ${const JsonEncoder.withIndent('  ').convert(body)}',
          );
        }
      }

      final headers = await _buildHeaders();

      final response = await _executeWithRetry(
        () => _httpClient
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(
              ApiConfig.receiveTimeout,
              onTimeout: () {
                throw const TimeoutException();
              },
            ),
      );

      stopwatch.stop();

      if (ApiConfig.enableHttpLogging) {
        debugPrint(
          '✅ [RESPONSE] ${response.statusCode} $path (${stopwatch.elapsedMilliseconds}ms)',
        );
        if (ApiConfig.logResponseBody) {
          debugPrint('   Body: ${response.body}');
        }
      }

      return _parseResponse(response);
    } catch (e) {
      stopwatch.stop();
      if (ApiConfig.enableHttpLogging) {
        debugPrint('❌ [ERROR] $path (${stopwatch.elapsedMilliseconds}ms): $e');
      }
      rethrow;
    }
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    var attempt = 0;

    while (attempt <= ApiConfig.maxRetries) {
      try {
        final response = await request();

        // Nếu 401 và chưa retry, thử refresh token
        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            attempt++;
            continue; // Retry với token mới
          }
        }

        return response;
      } on TimeoutException {
        if (attempt < ApiConfig.maxRetries) {
          final delay = _calculateRetryDelay(attempt);
          if (ApiConfig.enableHttpLogging) {
            debugPrint(
              '⏳ Timeout, retrying in ${delay.inMilliseconds}ms (attempt ${attempt + 1}/${ApiConfig.maxRetries})',
            );
          }
          await Future.delayed(delay);
          attempt++;
        } else {
          rethrow;
        }
      } on NetworkException {
        if (attempt < ApiConfig.maxRetries) {
          final delay = _calculateRetryDelay(attempt);
          if (ApiConfig.enableHttpLogging) {
            debugPrint(
              '📡 Network error, retrying in ${delay.inMilliseconds}ms (attempt ${attempt + 1}/${ApiConfig.maxRetries})',
            );
          }
          await Future.delayed(delay);
          attempt++;
        } else {
          rethrow;
        }
      }
    }

    throw const UnknownException(message: 'Đã hết số lần thử');
  }

  // ===== Helper Methods =====

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Gắn access token nếu có
    final token = await _getAccessToken?.call();
    if (token != null && token.isNotEmpty) {
      headers[ApiConfig.authHeaderKey] = '${ApiConfig.bearerPrefix} $token';
    }

    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    // Success cases
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Body không phải JSON
      }

      throw const ParseException(
        rawResponse: '<not JSON>',
        message: 'Phản hồi từ server không đúng định dạng JSON 🌿',
      );
    }

    // Error cases
    Map<String, dynamic>? parsedJson;
    try {
      parsedJson = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      // Ignore
    }

    throw exceptionFromHttpStatus(
      response.statusCode,
      response.body,
      parsedJson: parsedJson,
    );
  }

  Future<bool> _tryRefreshToken() async {
    // Tránh concurrent refresh
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 200));
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _getRefreshToken?.call();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (ApiConfig.enableHttpLogging) {
          debugPrint('🔑 Không có refresh token để refresh');
        }
        return false;
      }

      if (ApiConfig.enableHttpLogging) {
        debugPrint('🔄 Đang refresh access token...');
      }

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{'refresh_token': refreshToken}),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['data']?['access_token']?.toString();
        final newRefreshToken = data['data']?['refresh_token']?.toString();

        if (newAccessToken != null && newRefreshToken != null) {
          await _onTokenRefresh?.call(newAccessToken, newRefreshToken);
          if (ApiConfig.enableHttpLogging) {
            debugPrint('✅ Refresh token thành công');
          }
          return true;
        }
      }

      if (ApiConfig.enableHttpLogging) {
        debugPrint('❌ Refresh token thất bại: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      if (ApiConfig.enableHttpLogging) {
        debugPrint('❌ Lỗi khi refresh token: $e');
      }
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Duration _calculateRetryDelay(int attempt) {
    final baseMs = ApiConfig.initialRetryDelay.inMilliseconds;
    final multiplier = ApiConfig.retryMultiplier;
    final delayMs = baseMs * (multiplier * attempt);
    // Thêm jitter ngẫu nhiên để tránh thundering herd
    final jitter = Duration(milliseconds: (delayMs * 0.25).toInt());
    return Duration(milliseconds: delayMs) + jitter;
  }

  @override
  String toString() {
    return 'RealApiService(baseUrl: $baseUrl)';
  }
}
