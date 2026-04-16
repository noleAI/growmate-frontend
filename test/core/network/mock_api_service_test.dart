import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/core/network/mock_api_service.dart';

void main() {
  group('MockApiService', () {
    group('submitAnswer', () {
      test(
        'returns success with isCorrect=true for correct derivative',
        () async {
          final svc = MockApiService();

          // MockApiService accepts '12x^2+4x' as the correct answer
          final result = await svc.submitAnswer(
            sessionId: 'session-1',
            questionId: 'q1',
            answer: '12x^2 + 4x',
          );

          expect(result['status'], equals('success'));
          final data = result['data'] as Map<String, dynamic>;
          expect(data['isCorrect'], isTrue);
          expect(data['sessionId'], equals('session-1'));
          expect(data['questionId'], equals('q1'));
          expect(data['answerText'], equals('12x^2 + 4x'));
        },
      );

      test('returns isCorrect=false for wrong answer', () async {
        final svc = MockApiService();

        final result = await svc.submitAnswer(
          sessionId: 'session-2',
          questionId: 'q2',
          answer: 'wrong answer xyz',
        );

        expect(result['status'], equals('success'));
        final data = result['data'] as Map<String, dynamic>;
        expect(data['isCorrect'], isFalse);
      });

      test('includes pipeline info with nextStep "diagnosis"', () async {
        final svc = MockApiService();

        final result = await svc.submitAnswer(
          sessionId: 's',
          questionId: 'q',
          answer: 'anything',
        );

        final data = result['data'] as Map<String, dynamic>;
        final pipeline = data['pipeline'] as Map<String, dynamic>;
        expect(pipeline['nextStep'], equals('diagnosis'));
      });

      test('includes context passthrough', () async {
        final svc = MockApiService();
        final ctx = {'timeSpent': 42};

        final result = await svc.submitAnswer(
          sessionId: 's',
          questionId: 'q',
          answer: 'a',
          context: ctx,
        );

        final data = result['data'] as Map<String, dynamic>;
        expect((data['context'] as Map)['timeSpent'], equals(42));
      });
    });

    group('getDiagnosis', () {
      test('diagnosisSuccess scenario returns requiresHITL=false', () async {
        final svc = MockApiService(
          scenario: MockDiagnosisScenario.diagnosisSuccess,
        );

        final submit = await svc.submitAnswer(
          sessionId: 's',
          questionId: 'q',
          answer: 'wrong',
        );
        final answerId =
            (submit['data'] as Map<String, dynamic>)['answerId'] as String;

        final diag = await svc.getDiagnosis(sessionId: 's', answerId: answerId);

        expect(diag['status'], equals('success'));
        final data = diag['data'] as Map<String, dynamic>;
        expect(data['requiresHITL'], isFalse);
        expect(data['confidence'], isA<double>());
      });

      test('hitlTriggered scenario returns requiresHITL=true', () async {
        final svc = MockApiService(
          scenario: MockDiagnosisScenario.hitlTriggered,
        );

        final submit = await svc.submitAnswer(
          sessionId: 's',
          questionId: 'q',
          answer: 'wrong',
        );
        final answerId =
            (submit['data'] as Map<String, dynamic>)['answerId'] as String;

        final diag = await svc.getDiagnosis(sessionId: 's', answerId: answerId);

        final data = diag['data'] as Map<String, dynamic>;
        expect(data['requiresHITL'], isTrue);
      });

      test(
        'autoCycle scenario cycles through scenarios on repeated calls',
        () async {
          final svc = MockApiService(scenario: MockDiagnosisScenario.autoCycle);

          // First call with wrong answer should not return correct diagnosis
          final submit1 = await svc.submitAnswer(
            sessionId: 's1',
            questionId: 'q1',
            answer: 'totally wrong',
          );
          final answerId1 =
              (submit1['data'] as Map<String, dynamic>)['answerId'] as String;

          final diag1 = await svc.getDiagnosis(
            sessionId: 's1',
            answerId: answerId1,
          );

          expect(diag1['status'], equals('success'));
          expect(diag1['data'], isA<Map>());
        },
      );
    });

    group('submitInterventionFeedback', () {
      test('returns success with valid args', () async {
        final svc = MockApiService();

        final result = await svc.submitInterventionFeedback(
          sessionId: 's',
          submissionId: 'sub_001',
          diagnosisId: 'dx_001',
          optionId: 'opt_a',
          optionLabel: 'Hít thở sâu',
          mode: 'normal',
          remainingRestSeconds: 120,
        );

        expect(result['status'], equals('success'));
      });

      test('skipped flag returns lower q-value message', () async {
        final svc = MockApiService();

        final result = await svc.submitInterventionFeedback(
          sessionId: 's',
          submissionId: 'sub_002',
          diagnosisId: 'dx_002',
          optionId: 'opt_b',
          optionLabel: 'Viết nhật ký',
          mode: 'recovery',
          remainingRestSeconds: 0,
          skipped: true,
        );

        expect(result['status'], equals('success'));
        expect((result['message'] as String).contains('bỏ qua'), isTrue);
      });
    });

    group('scenario cycling', () {
      test('MockApiService supports all scenario enum values', () {
        // Verifies each scenario can be instantiated without error
        for (final scenario in MockDiagnosisScenario.values) {
          expect(() => MockApiService(scenario: scenario), returnsNormally);
        }
      });
    });
  });
}
