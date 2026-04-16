import '../../../../core/network/rest_api_client.dart';
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
    } catch (_) {
      return PendingSession.empty;
    }
  }
}
