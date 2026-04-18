import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/features/inspection/data/models/inspection_ops_models.dart';

void main() {
  group('parseInspectionMetricMap', () {
    test('keeps valid numeric values and drops invalid entries', () {
      final parsed = parseInspectionMetricMap(<String, dynamic>{
        'signature_expired_total': 3,
        'quiz_result_fetch_failures_total': '7',
        'resume_signature_grace_used_total': 5.9,
        '': 10,
        'invalid': 'abc',
      });

      expect(parsed, <String, int>{
        'signature_expired_total': 3,
        'quiz_result_fetch_failures_total': 7,
        'resume_signature_grace_used_total': 5,
      });
    });
  });

  group('InspectionRuntimeAlertsSnapshot', () {
    test('parses alerts payload and dispatch stats', () {
      final observedAt = DateTime(2026, 4, 1, 9, 30, 0);
      final snapshot = InspectionRuntimeAlertsSnapshot.fromJson(
        <String, dynamic>{
          'metrics': <String, dynamic>{'signature_expired_total': 8},
          'alerts': <dynamic>[
            <String, dynamic>{
              'name': 'runtime_metric_signature_expired_total',
              'metric': 'signature_expired_total',
              'value': 8,
              'threshold': 5,
              'severity': 'warning',
              'message': 'signature metric reached threshold',
            },
            <String, dynamic>{
              'name': 'runtime_metric_fetch_failures',
              'metric': 'quiz_result_fetch_failures_total',
              'value': '4',
              'threshold': '3',
              'severity': 'warning',
              'message': 'result fetch failures increased',
            },
            'ignored item',
          ],
          'count': '2',
          'dispatch': false,
          'attempted': '1',
          'sent': 1,
          'failed': 0,
          'skipped_rate_limited': '0',
          'skipped_no_webhook': 0,
        },
        observedAt: observedAt,
      );

      expect(snapshot.metrics['signature_expired_total'], 8);
      expect(snapshot.alerts.length, 2);
      expect(snapshot.alerts.first.metric, 'signature_expired_total');
      expect(snapshot.alerts.first.observedAt, observedAt);
      expect(snapshot.count, 2);
      expect(snapshot.dispatch, isFalse);
      expect(snapshot.dispatchStats, <String, int>{
        'attempted': 1,
        'sent': 1,
        'failed': 0,
        'skipped_rate_limited': 0,
        'skipped_no_webhook': 0,
      });
    });

    test('falls back count to alerts length when count is missing', () {
      final snapshot = InspectionRuntimeAlertsSnapshot.fromJson(
        <String, dynamic>{
          'alerts': <dynamic>[
            <String, dynamic>{
              'name': 'runtime_metric_signature_expired_total',
              'metric': 'signature_expired_total',
              'value': 8,
              'threshold': 5,
              'severity': 'warning',
              'message': 'signature metric reached threshold',
            },
          ],
        },
      );

      expect(snapshot.count, 1);
      expect(snapshot.alerts.length, 1);
    });
  });
}
