import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/features/quota/data/models/quota_status.dart';

void main() {
  group('QuotaStatus.fromJson', () {
    test('parses chatbot quota payload including reset_at', () {
      final quota = QuotaStatus.fromJson({
        'used': 12,
        'limit': 30,
        'remaining': 18,
        'reset_at': '2026-04-18T00:00:00+07:00',
      });

      expect(quota.used, 12);
      expect(quota.limit, 30);
      expect(quota.remaining, 18);
      expect(quota.resetAt, DateTime.parse('2026-04-18T00:00:00+07:00'));
    });

    test('parses numeric strings and clamps remaining to valid range', () {
      final quota = QuotaStatus.fromJson({
        'used': '45',
        'limit': '30',
        'remaining': '-5',
      });

      expect(quota.used, 45);
      expect(quota.limit, 30);
      expect(quota.remaining, 0);
    });
  });

  group('QuotaStatus.fromRateLimitDetails', () {
    test('builds exhausted quota from backend 429 details', () {
      final quota = QuotaStatus.fromRateLimitDetails({'limit': 30, 'used': 30});

      expect(quota.limit, 30);
      expect(quota.used, 30);
      expect(quota.remaining, 0);
      expect(quota.isExceeded, isTrue);
    });

    test('uses fallback limit when details are missing', () {
      final quota = QuotaStatus.fromRateLimitDetails(null, fallbackLimit: 25);

      expect(quota.limit, 25);
      expect(quota.used, 25);
      expect(quota.remaining, 0);
    });
  });
}
