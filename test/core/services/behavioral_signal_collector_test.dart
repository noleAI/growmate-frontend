import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/core/services/behavioral_signal_collector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BehavioralSignalCollector collector;
  late List<List<Map<String, dynamic>>> submittedBatches;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    collector = BehavioralSignalCollector.instance;
    collector.resetForTest();

    submittedBatches = <List<Map<String, dynamic>>>[];
  });

  tearDown(() {
    collector.resetForTest();
  });

  test('mac dinh khong thu thap khi chua co consent', () {
    final isolatedCollector = BehavioralSignalCollector.instance;
    isolatedCollector.resetForTest();

    final isolatedBatches = <List<Map<String, dynamic>>>[];

    fakeAsync((async) {
      isolatedCollector.attachBatchSubmitter((batch) async {
        isolatedBatches.add(
          batch
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
        );
      });

      isolatedCollector.startQuestionTimer();
      isolatedCollector.recordKeystroke(characterCount: 5);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      expect(isolatedBatches, isEmpty);
    });
  });

  test('gom batch dung chu ky 5 giay', () {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'data_consent_accepted': true,
    });

    fakeAsync((async) {
      collector.attachBatchSubmitter((batch) async {
        submittedBatches.add(
          batch
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
        );
      });
      collector.setCollectionEnabled(true);
      collector.startQuestionTimer();
      async.flushMicrotasks();
      collector.recordKeystroke(characterCount: 5);

      async.elapse(const Duration(seconds: 4, milliseconds: 999));
      async.flushMicrotasks();
      expect(submittedBatches, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();

      expect(submittedBatches.length, 1);
      expect(submittedBatches.single.length, 1);
      expect(submittedBatches.single.single['trigger'], 'periodic');
      expect(submittedBatches.single.single['typedChars'], 5);
    });
  });

  test('tinh typingSpeed va correctionRate chinh xac', () {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'data_consent_accepted': true,
    });

    fakeAsync((async) {
      collector.attachBatchSubmitter((batch) async {
        submittedBatches.add(
          batch
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
        );
      });
      collector.setCollectionEnabled(true);
      collector.startQuestionTimer();
      async.flushMicrotasks();
      collector.recordKeystroke(characterCount: 10);
      collector.recordCorrection();
      collector.recordCorrection();

      async.elapse(const Duration(seconds: 2));
      collector.setElapsedOverridesForTest(batchElapsedSeconds: 2.0);
      collector.recordSubmit();
      async.flushMicrotasks();

      expect(submittedBatches.length, 1);
      expect(submittedBatches.single.length, 1);

      final signal = submittedBatches.single.single;
      expect(signal['trigger'], 'submit');
      expect(signal['typedChars'], 10);
      expect(signal['corrections'], 2);
      expect(signal['typingSpeed'] as double, closeTo(5.0, 0.001));
      expect(signal['correctionRate'] as double, closeTo(0.2, 0.000001));
    });
  });

  test('flush batch khi app pause', () {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'data_consent_accepted': true,
    });

    fakeAsync((async) {
      collector.attachBatchSubmitter((batch) async {
        submittedBatches.add(
          batch
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
        );
      });
      collector.setCollectionEnabled(true);
      collector.startQuestionTimer();
      async.flushMicrotasks();
      collector.recordKeystroke(characterCount: 4);

      async.elapse(const Duration(seconds: 1));
      collector.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.flushMicrotasks();

      expect(submittedBatches.length, 1);
      expect(submittedBatches.single.length, 1);
      expect(submittedBatches.single.single['trigger'], 'lifecycle_paused');
      expect(submittedBatches.single.single['typedChars'], 4);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(submittedBatches.length, 1);
    });
  });
}
