import '../../../../core/network/rest_api_client.dart';
import '../models/quota_status.dart';

/// Repository for fetching user's daily quiz/session quota from backend.
///
/// The primary endpoint is `GET /api/v1/quota` (quiz/session daily quota).
/// For **chat** quota, use the chat-specific repository instead.
class QuotaRepository {
  QuotaRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  /// Fetches the current quota status from `GET /api/v1/quota`.
  ///
  /// Returns [QuotaStatus.defaultQuota] on error so the UI can still render.
  Future<QuotaStatus> fetchQuota() async {
    try {
      return await _fetchQuota(path: '/quota');
    } catch (_) {
      return QuotaStatus.defaultQuota;
    }
  }

  Future<QuotaStatus> _fetchQuota({required String path}) async {
    final json = await _client.get(path);
    final data = _unwrapPayload(json);
    return QuotaStatus.fromJson(data);
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return json;
  }
}
