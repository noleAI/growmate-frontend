import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/agentic_models.dart';
import '../error/app_exceptions.dart';
import '../network/academic_api_service.dart';
import '../network/api_config.dart';
import '../network/hmac_signer.dart';

/// Production implementation of [AcademicApiService].
///
/// Mirrors [RealAgenticApiService] but targets the `/academic` route
/// prefix instead of `/sessions`. Shares the same auth, retry, and
/// HMAC signing strategy.
class RealAcademicApiService implements AcademicApiService {
  RealAcademicApiService({
    http.Client? httpClient,
    required Future<String?> Function() getAccessToken,
    required Future<String?> Function() getRefreshToken,
    required Future<void> Function(String accessToken, String refreshToken)
    onTokenRefresh,
  }) : _httpClient = httpClient ?? http.Client(),
       _getAccessToken = getAccessToken,
       _getRefreshToken = getRefreshToken,
       _onTokenRefresh = onTokenRefresh;

  final http.Client _httpClient;
  final Future<String?> Function() _getAccessToken;
  final Future<String?> Function() _getRefreshToken;
  final Future<void> Function(String, String) _onTokenRefresh;

  bool _isRefreshing = false;

  String get _baseUrl => ApiConfig.restApiBaseUrl;

  // ─── Academic Session ──────────────────────────────────────────────────

  @override
  Future<AgenticSessionResponse> createAcademicSession({
    required String subject,
    required String topic,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? onboardingResults,
  }) async {
    final body = <String, dynamic>{'subject': subject, 'topic': topic};
    if (mode != null) body['mode'] = mode;
    if (classificationLevel != null) {
      body['classification_level'] = classificationLevel;
    }
    if (onboardingResults != null) {
      body['onboarding_results'] = onboardingResults;
    }
    final json = await _post('/academic', body);
    return AgenticSessionResponse.fromJson(json);
  }

  @override
  Future<SessionUpdateResponse> updateAcademicSession({
    required String sessionId,
    required String status,
  }) async {
    final json = await _patch('/academic/$sessionId', {'status': status});
    return SessionUpdateResponse.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> getAcademicPending() async {
    return _get('/academic/pending');
  }

  @override
  Future<AgenticInteractionResponse> academicInteract({
    required String sessionId,
    required String actionType,
    String? quizId,
    Map<String, dynamic>? responseData,
    String? mode,
    String? classificationLevel,
    Map<String, dynamic>? xpData,
    Map<String, dynamic>? onboardingResults,
    Map<String, dynamic>? analyticsData,
    bool isOffTopic = false,
    bool resume = false,
  }) async {
    final body = <String, dynamic>{'action_type': actionType};
    if (quizId != null) body['quiz_id'] = quizId;
    if (responseData != null) body['response_data'] = responseData;
    if (mode != null) body['mode'] = mode;
    if (classificationLevel != null) {
      body['classification_level'] = classificationLevel;
    }
    if (xpData != null) body['xp_data'] = xpData;
    if (onboardingResults != null) {
      body['onboarding_results'] = onboardingResults;
    }
    if (analyticsData != null) body['analytics_data'] = analyticsData;
    if (isOffTopic) body['is_off_topic'] = true;
    if (resume) body['resume'] = true;

    final json = await _post('/academic/$sessionId/interact', body);
    return AgenticInteractionResponse.fromJson(json);
  }

  // ─── Core HTTP Methods ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _buildHeaders();

    _log('GET', path);

    final response = await _executeWithRetry(
      () => _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout),
    );

    _logResponse(response, path);
    return _parseResponse(response);
  }

  static final _hmacPathPattern = RegExp(r'/academic/[^/]+/interact$');

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _buildHeaders();
    final bodyBytes = utf8.encode(jsonEncode(body));

    if (_hmacPathPattern.hasMatch(path)) {
      headers.addAll(
        HmacSigner.sign(method: 'POST', path: path, bodyBytes: bodyBytes),
      );
    }

    _log('POST', path, body: body);

    final response = await _executeWithRetry(
      () => _httpClient
          .post(uri, headers: headers, body: bodyBytes)
          .timeout(ApiConfig.receiveTimeout),
    );

    _logResponse(response, path);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _buildHeaders();

    _log('PATCH', path, body: body);

    final response = await _executeWithRetry(
      () => _httpClient
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.receiveTimeout),
    );

    _logResponse(response, path);
    return _parseResponse(response);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers[ApiConfig.authHeaderKey] = '${ApiConfig.bearerPrefix} $token';
    }

    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}

      throw const ParseException(
        rawResponse: '<not JSON>',
        message: 'Phản hồi từ server không đúng định dạng JSON',
      );
    }

    Map<String, dynamic>? parsedJson;
    try {
      parsedJson = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}

    throw exceptionFromHttpStatus(
      response.statusCode,
      response.body,
      parsedJson: parsedJson,
    );
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    var attempt = 0;

    while (attempt <= ApiConfig.maxRetries) {
      try {
        final response = await request();

        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            attempt++;
            continue;
          }
        }

        return response;
      } on TimeoutException {
        if (attempt < ApiConfig.maxRetries) {
          await Future.delayed(_retryDelay(attempt));
          attempt++;
        } else {
          rethrow;
        }
      } on NetworkException {
        if (attempt < ApiConfig.maxRetries) {
          await Future.delayed(_retryDelay(attempt));
          attempt++;
        } else {
          rethrow;
        }
      }
    }

    throw const UnknownException(message: 'Đã hết số lần thử');
  }

  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 200));
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['data']?['access_token']?.toString();
        final newRefresh = data['data']?['refresh_token']?.toString();

        if (newAccess != null && newRefresh != null) {
          await _onTokenRefresh(newAccess, newRefresh);
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Duration _retryDelay(int attempt) {
    final baseMs = ApiConfig.initialRetryDelay.inMilliseconds;
    final delayMs = baseMs * (1 << attempt);
    return Duration(milliseconds: delayMs + (delayMs ~/ 4));
  }

  void _log(String method, String path, {Map<String, dynamic>? body}) {
    if (!kDebugMode || !ApiConfig.enableHttpLogging) return;
    debugPrint('📚 [ACADEMIC] $method $path');
    if (body != null && ApiConfig.logResponseBody) {
      debugPrint(
        '   Body: ${const JsonEncoder.withIndent('  ').convert(body)}',
      );
    }
  }

  void _logResponse(http.Response response, String path) {
    if (!kDebugMode || !ApiConfig.enableHttpLogging) return;
    debugPrint('📚 [ACADEMIC] ${response.statusCode} $path');
  }
}
