import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/auth_token_storage.dart';
import '../models/quota_status.dart';

/// Repository for fetching user's daily LLM quota from backend.
class QuotaRepository {
  QuotaRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches the current quota status from `GET /api/v1/quota`.
  ///
  /// Returns [QuotaStatus.defaultQuota] on error so the UI can still render.
  Future<QuotaStatus> fetchQuota() async {
    try {
      final token = await GlobalTokenStorage.instance.getAccessToken();
      final uri = Uri.parse('${ApiConfig.restApiBaseUrl}/api/v1/quota');
      final response = await _client.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return QuotaStatus.fromJson(data);
      }

      return QuotaStatus.defaultQuota;
    } catch (_) {
      return QuotaStatus.defaultQuota;
    }
  }
}
