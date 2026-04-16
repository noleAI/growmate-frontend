/// Data models for the structured AI response block types.
library;

import 'package:flutter/foundation.dart';

import '../../../data/models/agentic_models.dart' as agentic;

// ── Enums ───────────────────────────────────────────────────────────────────

enum DecisionStatus { pending, accepted, rejected, modified }

enum DecisionActionType { accept, reject, askWhy, modify }

enum BlockPriority { low, medium, high }

// ── Base ────────────────────────────────────────────────────────────────────

@immutable
sealed class AiBlock {
  const AiBlock({required this.id, required this.timestamp, this.delayMs = 0});

  final String id;
  final DateTime timestamp;
  final int delayMs;
}

// ── Block Type 1: Insight ───────────────────────────────────────────────────

class InsightBlock extends AiBlock {
  const InsightBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.content,
    required this.confidence,
    this.evidenceSource,
    this.updatedAgo,
  });

  final String content;
  final double confidence;
  final String? evidenceSource;
  final String? updatedAgo;
}

// ── Block Type 2: Reasoning Chain ───────────────────────────────────────────

class ReasoningStep {
  const ReasoningStep({required this.index, required this.description});

  final int index;
  final String description;
}

class ReasoningBlock extends AiBlock {
  const ReasoningBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.steps,
    required this.uncertainty,
  });

  final List<ReasoningStep> steps;
  final double uncertainty;
}

// ── Block Type 3: Decision (HITL) ───────────────────────────────────────────

class DecisionAction {
  const DecisionAction({required this.type, required this.label});

  final DecisionActionType type;
  final String label;
}

class DecisionBlock extends AiBlock {
  const DecisionBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.recommendation,
    required this.reason,
    this.priority = BlockPriority.medium,
    this.duration,
    this.actions = const [],
    this.status = DecisionStatus.pending,
  });

  final String recommendation;
  final String reason;
  final BlockPriority priority;
  final String? duration;
  final List<DecisionAction> actions;
  final DecisionStatus status;

  DecisionBlock copyWith({DecisionStatus? status}) {
    return DecisionBlock(
      id: id,
      timestamp: timestamp,
      delayMs: delayMs,
      recommendation: recommendation,
      reason: reason,
      priority: priority,
      duration: duration,
      actions: actions,
      status: status ?? this.status,
    );
  }
}

// ── Block Type 4: Emotional Check ───────────────────────────────────────────

class EmotionOption {
  const EmotionOption({
    required this.emoji,
    required this.label,
    required this.key,
  });

  final String emoji;
  final String label;
  final String key;
}

class EmotionCheckBlock extends AiBlock {
  const EmotionCheckBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.message,
    required this.probabilities,
    required this.options,
  });

  final String message;
  final Map<String, double> probabilities;
  final List<EmotionOption> options;
}

// ── Block Type 5: Status Update ─────────────────────────────────────────────

class StatusChange {
  const StatusChange({required this.description});

  final String description;
}

class StatusUpdateBlock extends AiBlock {
  const StatusUpdateBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.title,
    required this.changes,
    this.requiresConfirmation = false,
  });

  final String title;
  final List<StatusChange> changes;
  final bool requiresConfirmation;
}

// ── Block Type 6: Agentic Reasoning Trace ───────────────────────────────────

class ReasoningTraceBlock extends AiBlock {
  const ReasoningTraceBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.steps,
    required this.conclusion,
    required this.confidence,
    required this.mode,
  });

  final List<agentic.ReasoningStep> steps;
  final String conclusion;
  final double confidence;
  final String mode;
}

// ── Block Type 7: Knowledge Card (RAG) ──────────────────────────────────────

class KnowledgeCardBlock extends AiBlock {
  const KnowledgeCardBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.chunks,
    required this.query,
  });

  final List<agentic.KnowledgeChunk> chunks;
  final String query;
}

// ── Block Type 8: Self-Reflection ───────────────────────────────────────────

class ReflectionBlock extends AiBlock {
  const ReflectionBlock({
    required super.id,
    required super.timestamp,
    super.delayMs,
    required this.reflection,
    required this.stepNumber,
  });

  final agentic.ReflectionResult reflection;
  final int stepNumber;
}
