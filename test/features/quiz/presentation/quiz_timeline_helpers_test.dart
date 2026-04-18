import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/data/models/agentic_models.dart';
import 'package:growmate_frontend/features/quiz/presentation/pages/quiz_page.dart';

void main() {
  group('inferAgentBucketFromReasoningStep', () {
    test('maps academic tools to academic bucket', () {
      const step = ReasoningStep(
        step: 1,
        tool: 'get_academic_beliefs',
        resultSummary: '',
      );

      expect(inferAgentBucketFromReasoningStep(step), 'academic');
    });

    test('maps empathy tools to empathy bucket', () {
      const step = ReasoningStep(
        step: 2,
        tool: 'get_empathy_state',
        resultSummary: '',
      );

      expect(inferAgentBucketFromReasoningStep(step), 'empathy');
    });

    test('maps other tools to strategy bucket', () {
      const step = ReasoningStep(
        step: 3,
        tool: 'get_strategy_suggestion',
        resultSummary: '',
      );

      expect(inferAgentBucketFromReasoningStep(step), 'strategy');
    });
  });

  group('inferReasoningStepStatus', () {
    test('returns failed when summary contains error token', () {
      const step = ReasoningStep(
        step: 1,
        tool: 'get_academic_beliefs',
        resultSummary: 'error while fetching beliefs',
      );

      expect(
        inferReasoningStepStatus(step, isLast: false, isLoading: false),
        ReasoningStepStatus.failed,
      );
    });

    test('returns fallback when summary contains fallback token', () {
      const step = ReasoningStep(
        step: 2,
        tool: 'get_empathy_state',
        resultSummary: 'fallback to cached profile',
      );

      expect(
        inferReasoningStepStatus(step, isLast: false, isLoading: false),
        ReasoningStepStatus.fallback,
      );
    });

    test('returns running for last step while loading', () {
      const step = ReasoningStep(
        step: 3,
        tool: 'get_strategy_suggestion',
        resultSummary: 'processing',
      );

      expect(
        inferReasoningStepStatus(step, isLast: true, isLoading: true),
        ReasoningStepStatus.running,
      );
    });

    test('returns completed for normal step', () {
      const step = ReasoningStep(
        step: 4,
        tool: 'search_knowledge',
        resultSummary: 'retrieved matching chapters',
      );

      expect(
        inferReasoningStepStatus(step, isLast: false, isLoading: false),
        ReasoningStepStatus.completed,
      );
    });
  });
}
