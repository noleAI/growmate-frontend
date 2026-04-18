import '../../../../core/network/rest_api_client.dart';
import '../models/inspection_ops_models.dart';

class InspectionOpsRepository {
  InspectionOpsRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  Future<InspectionRuntimeMetricsSnapshot> getRuntimeMetrics() async {
    final response = await _client.get('/inspection/runtime-metrics');
    final payload = _unwrapPayload(response);

    return InspectionRuntimeMetricsSnapshot.fromJson(
      payload,
      observedAt: DateTime.now(),
    );
  }

  Future<InspectionRuntimeAlertsSnapshot> getRuntimeAlerts({
    bool dispatch = false,
  }) async {
    final queryParams = dispatch
        ? const <String, String>{'dispatch': 'true'}
        : null;
    final response = await _client.get(
      '/inspection/runtime-alerts',
      queryParams: queryParams,
    );
    final payload = _unwrapPayload(response);

    return InspectionRuntimeAlertsSnapshot.fromJson(
      payload,
      observedAt: DateTime.now(),
    );
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    for (final key in const <String>['data', 'result', 'payload']) {
      final nested = raw[key];
      if (nested is Map) {
        final mapped = Map<String, dynamic>.from(nested);
        if (mapped.containsKey('metrics') || mapped.containsKey('alerts')) {
          return mapped;
        }
      }
    }

    for (final key in const <String>['data', 'result', 'payload']) {
      final nested = raw[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }

    return raw;
  }
}
