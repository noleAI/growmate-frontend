import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/agentic_session/presentation/cubit/agentic_session_cubit.dart';
import '../../../features/agentic_session/presentation/cubit/agentic_session_state.dart';
import '../../../shared/widgets/ai_blocks/ai_block_model.dart';
import 'ai_companion_cubit.dart';

/// Bridges [AgenticSessionCubit] state changes to [AiCompanionCubit].
///
/// Place this as a transparent wrapper around the app shell so it can observe
/// both cubits. It does NOT render anything itself.
///
/// Mapping table:
/// | `AgenticPhase`  | `AiCompanionCubit` method          |
/// |-----------------|-------------------------------------|
/// | processing      | `startThinking()`                   |
/// | interacting     | `finishThinking()`                  |
/// | hitlPending     | `pushBlock(DecisionBlock)`          |
/// | completed       | `onSessionComplete(...)`            |
/// | recovery        | `onEmotionDetected(...)`            |
/// | latestDashboard | `updateConfidence()`, `updateEmotion()` |
class SessionToCompanionBridge extends StatelessWidget {
  const SessionToCompanionBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AgenticSessionCubit, AgenticSessionState>(
      listenWhen: (prev, curr) =>
          prev.phase != curr.phase ||
          prev.latestDashboard != curr.latestDashboard ||
          prev.reasoningTrace != curr.reasoningTrace ||
          prev.knowledgeChunks != curr.knowledgeChunks ||
          prev.latestReflection != curr.latestReflection,
      listener: (context, state) {
        // Guard: AiCompanionCubit must be present.
        final AiCompanionCubit companion;
        try {
          companion = context.read<AiCompanionCubit>();
        } catch (_) {
          return;
        }

        // ── Dashboard updates (confidence + emotion) ──────────────────────
        final dashboard = state.latestDashboard;
        if (dashboard != null) {
          companion.updateConfidence(
            dashboard.academic.confidence,
            uncertainty: dashboard.academic.entropy,
          );
          // Resolve dominant particle-filter emotion.
          final particles = dashboard.empathy.particleDistribution;
          if (particles.isNotEmpty) {
            final dominant = particles.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
            companion.updateEmotion(dominant);
          }
        }

        // ── Agentic reasoning blocks ─────────────────────────────────────
        if (state.hasReasoningTrace && state.isAgenticMode) {
          _pushReasoningTrace(companion, state);
        }
        if (state.hasKnowledge) {
          _pushKnowledgeCards(companion, state);
        }
        if (state.latestReflection != null &&
            state.stepCount > 0 &&
            state.stepCount % 5 == 0) {
          _pushReflection(companion, state);
        }

        // ── Phase transitions ─────────────────────────────────────────────
        switch (state.phase) {
          case AgenticPhase.processing:
            companion.startThinking();

          case AgenticPhase.interacting:
          case AgenticPhase.ready:
            companion.finishThinking();

          case AgenticPhase.hitlPending:
            // Push a DecisionBlock so the AI Companion sheet can prompt user.
            _pushHitlDecision(companion, state);

          case AgenticPhase.completed:
            final confidence = dashboard?.academic.confidence ?? 0.7;
            final entropy = dashboard?.academic.entropy ?? 0.3;
            companion.onSessionComplete(
              confidence: confidence,
              uncertainty: entropy,
              topicRecommendation: _nextTopicLabel(state),
              reason:
                  state.currentContent ??
                  'Dựa trên kết quả phiên học vừa xong.',
              duration: '15 phút',
            );

          case AgenticPhase.recovery:
            _pushEmotionCheck(companion, state, dashboard);

          case AgenticPhase.idle:
          case AgenticPhase.error:
            companion.finishThinking();
        }
      },
      child: child,
    );
  }

  void _pushHitlDecision(
    AiCompanionCubit companion,
    AgenticSessionState state,
  ) {
    // Avoid duplicate blocks: only push if companion doesn't already have an
    // identical pending decision.
    final existing = companion.state.blocks.whereType<DecisionBlock>();
    final hitlId = 'hitl_${state.sessionId ?? 'session'}';
    if (existing.any((b) => b.id == hitlId)) return;

    final dashboard = state.latestDashboard;
    final confidence = dashboard?.academic.confidence ?? 0.65;
    final action = state.currentAction ?? 'tiếp tục luyện tập';

    final block = DecisionBlock(
      id: hitlId,
      timestamp: DateTime.now(),
      delayMs: 0,
      recommendation: 'AI đề xuất: $action',
      reason:
          state.currentContent ??
          'Dựa trên mô hình Bayesian và Particle Filter.',
      priority: confidence < 0.6 ? BlockPriority.high : BlockPriority.medium,
      duration: '~15 phút',
      actions: const [
        DecisionAction(type: DecisionActionType.accept, label: 'Đồng ý'),
        DecisionAction(type: DecisionActionType.reject, label: 'Không'),
        DecisionAction(type: DecisionActionType.askWhy, label: 'Vì sao?'),
        DecisionAction(type: DecisionActionType.modify, label: 'Chỉnh'),
      ],
    );
    companion.pushBlock(block);
  }

  void _pushEmotionCheck(
    AiCompanionCubit companion,
    AgenticSessionState state,
    dynamic dashboard,
  ) {
    final particles =
        (dashboard?.empathy.particleDistribution as Map<String, double>?) ?? {};
    final block = EmotionCheckBlock(
      id: 'emotion_recovery_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      delayMs: 0,
      message: 'Có vẻ bạn đang mệt. Bạn muốn nghỉ một chút không?',
      probabilities: particles,
      options: const [
        EmotionOption(key: 'break', label: 'Nghỉ 5 phút', emoji: '😌'),
        EmotionOption(key: 'continue', label: 'Tiếp tục', emoji: '💪'),
        EmotionOption(key: 'lighter', label: 'Bài dễ hơn', emoji: '🌿'),
      ],
    );
    companion.pushBlock(block);
  }

  String _nextTopicLabel(AgenticSessionState state) {
    if (state.topic != null) return state.topic!;
    if (state.subject != null) return state.subject!;
    return 'Chủ đề tiếp theo';
  }

  void _pushReasoningTrace(
    AiCompanionCubit companion,
    AgenticSessionState state,
  ) {
    final blockId = 'reasoning_step_${state.stepCount}';
    if (companion.state.blocks.any((b) => b.id == blockId)) return;

    companion.pushBlock(
      ReasoningTraceBlock(
        id: blockId,
        timestamp: DateTime.now(),
        steps: state.reasoningTrace,
        conclusion: state.reasoningContent ?? 'AI đã phân tích và quyết định.',
        confidence: state.reasoningConfidence ?? 0.5,
        mode: state.reasoningMode,
      ),
    );
  }

  void _pushKnowledgeCards(
    AiCompanionCubit companion,
    AgenticSessionState state,
  ) {
    final blockId = 'knowledge_step_${state.stepCount}';
    if (companion.state.blocks.any((b) => b.id == blockId)) return;

    final relevantChunks = state.knowledgeChunks
        .where((c) => c.content.isNotEmpty)
        .toList();
    if (relevantChunks.isEmpty) return;

    companion.pushBlock(
      KnowledgeCardBlock(
        id: blockId,
        timestamp: DateTime.now(),
        chunks: relevantChunks,
        query:
            state.lastOrchestratorStep?.reasoningTrace
                .where((s) => s.tool == 'search_knowledge')
                .map((s) => s.args['query'] as String? ?? '')
                .firstOrNull ??
            '',
      ),
    );
  }

  void _pushReflection(AiCompanionCubit companion, AgenticSessionState state) {
    final blockId = 'reflection_step_${state.stepCount}';
    if (companion.state.blocks.any((b) => b.id == blockId)) return;

    companion.pushBlock(
      ReflectionBlock(
        id: blockId,
        timestamp: DateTime.now(),
        reflection: state.latestReflection!,
        stepNumber: state.stepCount,
      ),
    );
  }
}
