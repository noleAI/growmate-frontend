import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class RealApiService implements ApiService {
  RealApiService({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

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
  // ignore: non_constant_identifier_names
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

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'RealApiService request failed (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected response format: ${response.body}');
  }
}
