import '../../../../core/network/rest_api_client.dart';
import '../../../../core/error/app_exceptions.dart';
import '../models/pending_session.dart';

/// Repository for session recovery via backend API.
class SessionRecoveryRepository {
  SessionRecoveryRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  /// GET /api/v1/sessions/pending — fetch latest active session.
  Future<PendingSession> getPendingSession() async {
    try {
      final json = await _client.get('/sessions/pending');
      return PendingSession.fromJson(json);
    } on AppException catch (e) {
      // Backward compatibility for deployments exposing singular route.
      if (e.statusCode == 404) {
        final json = await _client.get('/session/pending');
        return PendingSession.fromJson(json);
      }
      rethrow;
    }
  }
}
