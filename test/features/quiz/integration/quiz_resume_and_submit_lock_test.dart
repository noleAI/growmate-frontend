import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/features/quiz/presentation/pages/quiz_page.dart';
import 'package:growmate_frontend/features/recovery/data/repositories/session_recovery_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz resume snapshot', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await SessionRecoveryLocal.clear();
    });

    test('saveSnapshot and loadFreshSnapshot round-trip correctly', () async {
      await SessionRecoveryLocal.saveSnapshot(
        sessionId: 'session_123',
        lastQuestionIndex: 4,
        totalQuestions: 10,
        status: 'in_progress',
      );

      final snapshot = await SessionRecoveryLocal.loadFreshSnapshot();

      expect(snapshot, isNotNull);
      expect(snapshot!.sessionId, 'session_123');
      expect(snapshot.lastQuestionIndex, 4);
      expect(snapshot.totalQuestions, 10);
      expect(snapshot.status, 'in_progress');
    });

    test('clear removes pending snapshot', () async {
      await SessionRecoveryLocal.saveSnapshot(
        sessionId: 'session_abc',
        lastQuestionIndex: 1,
        totalQuestions: 5,
        status: 'in_progress',
      );

      await SessionRecoveryLocal.clear();

      final snapshot = await SessionRecoveryLocal.loadSnapshot();
      expect(snapshot, isNull);
    });
  });

  group('SubmitTapLock', () {
    test('blocks repeated submit until released', () {
      final lock = SubmitTapLock();

      expect(lock.isLocked, isFalse);
      expect(lock.tryAcquire(), isTrue);
      expect(lock.isLocked, isTrue);
      expect(lock.tryAcquire(), isFalse);

      lock.release();

      expect(lock.isLocked, isFalse);
      expect(lock.tryAcquire(), isTrue);
    });
  });
}
