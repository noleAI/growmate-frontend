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
    _cache[category] = response;
    return response;
  }

  /// Upload/replace config for [category] via `POST /configs/{category}`.
  ///
  /// Keeps local cache in sync after successful upload.
  Future<Map<String, dynamic>> uploadConfig(
    String category,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post('/configs/$category', payload);
    _cache[category] = response;
    return response;
  }

  /// Clears the in-memory cache for all categories.
  void clearCache() => _cache.clear();
}
