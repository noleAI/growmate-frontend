import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/agentic_models.dart';
import '../error/app_exceptions.dart';
import '../network/agentic_api_service.dart';
import '../network/api_config.dart';

/// Production implementation of [AgenticApiService].
///
/// Uses the same `http` package, token management, and retry strategy
/// as [RealApiService] but targets the actual agentic backend endpoints.
class RealAgenticApiService implements AgenticApiService {
  RealAgenticApiService({
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

  // ─── Session ───────────────────────────────────────────────────────────

  @override
  Future<AgenticSessionResponse> createSession({
    required String subject,
    required String topic,
  }) async {
    final json = await _post('/sessions', {'subject': subject, 'topic': topic});
    return AgenticSessionResponse.fromJson(json);
  }

  @override
  Future<SessionUpdateResponse> updateSession({
    required String sessionId,
    required String status,
  }) async {
    final json = await _patch('/sessions/$sessionId', {'status': status});
    return SessionUpdateResponse.fromJson(json);
  }

  // ─── Interaction ───────────────────────────────────────────────────────

  @override
  Future<AgenticInteractionResponse> interact({
    required String sessionId,
    required String actionType,
    String? quizId,
    Map<String, dynamic>? responseData,
  }) async {
    final body = <String, dynamic>{'action_type': actionType};
    if (quizId != null) body['quiz_id'] = quizId;
    if (responseData != null) body['response_data'] = responseData;

    final json = await _post('/sessions/$sessionId/interact', body);
    return AgenticInteractionResponse.fromJson(json);
  }

  @override
  Future<OrchestratorStepResponse> orchestratorStep({
    required String sessionId,
    String? questionId,
    Map<String, dynamic>? response,
    Map<String, dynamic>? behaviorSignals,
  }) async {
    final body = <String, dynamic>{'session_id': sessionId};
    if (questionId != null) body['question_id'] = questionId;
    if (response != null) body['response'] = response;
    if (behaviorSignals != null) body['behavior_signals'] = behaviorSignals;

    final json = await _post('/orchestrator/step', body);
    return OrchestratorStepResponse.fromJson(json);
  }

  // ─── Inspection ────────────────────────────────────────────────────────

  @override
  Future<InspectionBeliefResponse> getBeliefState({
    required String sessionId,
  }) async {
    final json = await _get('/inspection/belief-state/$sessionId');
    return InspectionBeliefResponse.fromJson(json);
  }

  @override
  Future<InspectionParticleResponse> getParticleState({
    required String sessionId,
  }) async {
    final json = await _get('/inspection/particle-state/$sessionId');
    return InspectionParticleResponse.fromJson(json);
  }

  @override
  Future<InspectionQValuesResponse> getQValues() async {
    final json = await _get('/inspection/q-values');
    return InspectionQValuesResponse.fromJson(json);
  }

  @override
  Future<InspectionAuditLogsResponse> getAuditLogs({
    required String sessionId,
  }) async {
    final json = await _get('/inspection/audit-logs/$sessionId');
    return InspectionAuditLogsResponse.fromJson(json);
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

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _buildHeaders();

    _log('POST', path, body: body);

    final response = await _executeWithRetry(
      () => _httpClient
          .post(uri, headers: headers, body: jsonEncode(body))
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
    final delayMs = baseMs * (1 << attempt); // 2^attempt
    return Duration(milliseconds: delayMs + (delayMs ~/ 4));
  }

  void _log(String method, String path, {Map<String, dynamic>? body}) {
    if (!kDebugMode || !ApiConfig.enableHttpLogging) return;
    debugPrint('🤖 [AGENTIC] $method $path');
    if (body != null && ApiConfig.logResponseBody) {
      debugPrint(
        '   Body: ${const JsonEncoder.withIndent('  ').convert(body)}',
      );
    }
  }

  void _logResponse(http.Response response, String path) {
    if (!kDebugMode || !ApiConfig.enableHttpLogging) return;
    debugPrint('🤖 [AGENTIC] ${response.statusCode} $path');
  }
}
