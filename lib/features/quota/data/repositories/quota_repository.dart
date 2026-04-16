import '../../../../core/network/rest_api_client.dart';
import '../models/quota_status.dart';

/// Repository for fetching user's daily LLM quota from backend.
class QuotaRepository {
  QuotaRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  /// Fetches the current quota status from `GET /api/v1/quota`.
  ///
  /// Returns [QuotaStatus.defaultQuota] on error so the UI can still render.
  Future<QuotaStatus> fetchQuota() async {
    try {
      final json = await _client.get('/quota');
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return QuotaStatus.fromJson(data);
    } catch (_) {
      return QuotaStatus.defaultQuota;
    }
  }
}
