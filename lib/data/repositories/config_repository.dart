import '../../core/network/rest_api_client.dart';

/// Repository for fetching remote configuration from
/// `GET /configs/{category}`.
///
/// Configs are cached in-memory after first fetch per category.
class ConfigRepository {
  ConfigRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;
  final Map<String, Map<String, dynamic>> _cache = {};

  /// Fetches config for [category] from backend.
  ///
  /// Returns cached value if already fetched; pass [forceRefresh] to
  /// bypass the cache.
  Future<Map<String, dynamic>> getConfig(
    String category, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(category)) {
      return _cache[category]!;
    }
    final response = await _client.get('/configs/$category');
    final payload = _unwrapPayload(response);
    _cache[category] = payload;
    return payload;
  }

  /// Upload/replace config for [category] via `POST /configs/{category}`.
  ///
  /// Keeps local cache in sync after successful upload.
  Future<Map<String, dynamic>> uploadConfig(
    String category,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post('/configs/$category', payload);
    final normalized = _unwrapPayload(response);
    _cache[category] = normalized;
    return normalized;
  }

  /// Clears the in-memory cache for all categories.
  void clearCache() => _cache.clear();

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    for (final key in const <String>['data', 'result', 'payload']) {
      final nested = raw[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return raw;
  }
}
