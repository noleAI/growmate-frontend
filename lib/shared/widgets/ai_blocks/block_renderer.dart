import 'package:flutter/material.dart';

import 'ai_block_model.dart';
import 'insight_block.dart';
import 'reasoning_block.dart';
import 'decision_block.dart';
import 'emotion_check_block.dart';
import 'status_block.dart';
import '../ai_reasoning_trace_widget.dart';
import '../ai_knowledge_card_widget.dart';
import '../ai_reflection_widget.dart';

/// Dispatches an [AiBlock] to the correct widget.
class AiBlockRenderer extends StatelessWidget {
  const AiBlockRenderer({
    super.key,
    required this.block,
    this.delayMs = 0,
    this.onDecisionAccept,
    this.onDecisionReject,
    this.onDecisionAskWhy,
    this.onDecisionModify,
    this.onEmotionSelected,
  });

  final AiBlock block;
  final int delayMs;
  final VoidCallback? onDecisionAccept;
  final VoidCallback? onDecisionReject;
  final VoidCallback? onDecisionAskWhy;
  final VoidCallback? onDecisionModify;
  final ValueChanged<String>? onEmotionSelected;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      InsightBlock b => InsightBlockWidget(block: b, delayMs: delayMs),
      ReasoningBlock b => ReasoningBlockWidget(block: b, delayMs: delayMs),
      DecisionBlock b => DecisionBlockWidget(
        block: b,
        delayMs: delayMs,
        onAccept: onDecisionAccept,
        onReject: onDecisionReject,
        onAskWhy: onDecisionAskWhy,
        onModify: onDecisionModify,
      ),
      EmotionCheckBlock b => EmotionCheckBlockWidget(
        block: b,
        delayMs: delayMs,
        onOptionSelected: onEmotionSelected,
      ),
      StatusUpdateBlock b => StatusBlockWidget(block: b, delayMs: delayMs),
      ReasoningTraceBlock b => AiReasoningTraceWidget(
        steps: b.steps,
        conclusion: b.conclusion,
        confidence: b.confidence,
      ),
      KnowledgeCardBlock b => AiKnowledgeCardWidget(
        chunks: b.chunks,
        query: b.query,
      ),
      ReflectionBlock b => AiReflectionWidget(
        reflection: b.reflection,
        stepNumber: b.stepNumber,
      ),
    };
  }
}
