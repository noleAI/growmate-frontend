import 'dart:async';
import 'dart:convert';
import 'dart:math' show pow;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../error/app_exceptions.dart';
import '../network/api_config.dart';
import '../network/api_service.dart';

/// Production-ready REST API service.
///
/// **DEPRECATED**: The endpoints used here (`/quiz/submit-answer`,
/// `/quiz/submit-batch`, `/diagnosis/get`, etc.) do not exist in the current
/// backend. Use [QuizApiRepository] for quiz and [AgenticApiService] /
/// [RealAgenticApiService] for agentic interaction.
///
/// Features:
/// - Auth header injection (Bearer token)
/// - Automatic token refresh on 401
/// - Retry with exponential backoff
/// - Timeout handling
/// - Request/response logging (debug only)
/// - Unified error handling via [AppException] hierarchy
@Deprecated(
  'Use QuizApiRepository for quiz flow, RealAgenticApiService for agentic flow.',
)
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
  bool _signalsEndpointUnavailable = false;
  bool _didLogSignalsEndpointUnavailable = false;
  bool _batchSubmitEndpointUnavailable = false;
  bool _didLogBatchSubmitEndpointUnavailable = false;

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
  }) async {
    if (_signalsEndpointUnavailable) {
      return _buildSignalsSkippedResponse(
        sessionId: sessionId,
        skippedCount: signals.length,
      );
    }

    try {
      return await _post('/signals/batch', <String, dynamic>{
        'sessionId': sessionId,
        'signals': signals,
      });
    } on AppException catch (error) {
      if (_isSignalsEndpointNotFound(error)) {
        _signalsEndpointUnavailable = true;

        if (ApiConfig.enableHttpLogging && !_didLogSignalsEndpointUnavailable) {
          _didLogSignalsEndpointUnavailable = true;
          debugPrint(
            '⚠️ /signals/batch not found (404). Disable remote signals sync for current app session.',
          );
        }

        return _buildSignalsSkippedResponse(
          sessionId: sessionId,
          skippedCount: signals.length,
        );
      }
      rethrow;
    }
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

  @override
  Future<Map<String, dynamic>> submitBatchAnswers({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    if (_batchSubmitEndpointUnavailable) {
      return _submitBatchAnswersSequentially(
        sessionId: sessionId,
        answers: answers,
      );
    }

    try {
      return await _post('/quiz/submit-batch', <String, dynamic>{
        'sessionId': sessionId,
        'answers': answers,
      });
    } on AppException catch (error) {
      if (_isBatchSubmitEndpointNotFound(error)) {
        _batchSubmitEndpointUnavailable = true;

        if (ApiConfig.enableHttpLogging &&
            !_didLogBatchSubmitEndpointUnavailable) {
          _didLogBatchSubmitEndpointUnavailable = true;
          debugPrint(
            '⚠️ /quiz/submit-batch not found (404). Falling back to sequential /quiz/submit-answer calls.',
          );
        }

        return _submitBatchAnswersSequentially(
          sessionId: sessionId,
          answers: answers,
        );
      }
      rethrow;
    }
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
    final delayMs = (baseMs * pow(multiplier, attempt)).toInt();
    // Thêm jitter ngẫu nhiên để tránh thundering herd
    final jitter = Duration(milliseconds: (delayMs * 0.25).toInt());
    return Duration(milliseconds: delayMs) + jitter;
  }

  bool _isSignalsEndpointNotFound(AppException error) {
    return error.statusCode == 404 || error.code == 'NOT_FOUND';
  }

  bool _isBatchSubmitEndpointNotFound(AppException error) {
    final statusCode = error.statusCode;
    final code = error.code.toUpperCase();
    final message = error.message.toLowerCase();

    if (statusCode == 404 || statusCode == 405 || statusCode == 501) {
      return true;
    }

    if (code == 'NOT_FOUND' || code == 'METHOD_NOT_ALLOWED') {
      return true;
    }

    if ((statusCode == 400 || statusCode == 422) &&
        (message.contains('submit-batch') ||
            message.contains('batch endpoint') ||
            message.contains('not implemented'))) {
      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>> _submitBatchAnswersSequentially({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final submissionIds = <String>[];

    for (final entry in answers) {
      final rawQuestionId = entry['questionId'] ?? entry['question_id'];
      final rawAnswer =
          entry['answerText'] ?? entry['answer_text'] ?? entry['answer'];

      final questionId = rawQuestionId?.toString().trim() ?? '';
      final answerText = rawAnswer?.toString() ?? '';

      if (questionId.isEmpty || answerText.trim().isEmpty) {
        throw const ValidationException(
          message: 'Thiếu question_id hoặc answer khi nộp toàn bộ bài.',
        );
      }

      final response = await submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        answer: answerText,
      );

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final submissionId =
            data['submissionId']?.toString() ??
            data['submission_id']?.toString() ??
            data['answerId']?.toString() ??
            data['answer_id']?.toString();
        if (submissionId != null && submissionId.isNotEmpty) {
          submissionIds.add(submissionId);
        }
      }
    }

    return <String, dynamic>{
      'status': 'success',
      'message': 'Batch answers accepted via sequential submit fallback.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'submissionIds': submissionIds,
        'totalSubmitted': answers.length,
      },
      'meta': <String, dynamic>{
        'source': 'real-api',
        'fallback': 'sequential-submit-answer',
      },
    };
  }

  Map<String, dynamic> _buildSignalsSkippedResponse({
    required String sessionId,
    required int skippedCount,
  }) {
    return <String, dynamic>{
      'status': 'skipped',
      'message':
          'Behavioral signals endpoint unavailable. Signals skipped for this session.',
      'data': <String, dynamic>{
        'sessionId': sessionId,
        'skippedCount': skippedCount,
      },
      'meta': <String, dynamic>{
        'source': 'real-api',
        'reason': 'signals_endpoint_unavailable',
      },
    };
  }

  @override
  String toString() {
    return 'RealApiService(baseUrl: $baseUrl)';
  }
}
