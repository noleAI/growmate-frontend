import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/ai_blocks/ai_block_model.dart';
import '../../../shared/widgets/ai_orb/ai_orb_state.dart';
import 'ai_companion_state.dart';

/// Central state machine for the AI Companion experience.
///
/// Orchestrates:
/// - AI block list (structured response cards shown in the companion sheet)
/// - AI Orb visual state
/// - HITL actions: accept / reject / ask-why / modify on [DecisionBlock]s
/// - Confidence + uncertainty tracking
/// - Particle Filter emotion state
///
/// Designed to be provided at the app shell level so all screens share the
/// same AI state. Screens listen via [BlocBuilder] or [context.read].
class AiCompanionCubit extends Cubit<AiCompanionState> {
  AiCompanionCubit() : super(const AiCompanionState());

  // ── Orb / emotion ──────────────────────────────────────────────────────────

  /// Update confidence from a fresh diagnosis result.
  void updateConfidence(double confidence, {double uncertainty = 0.0}) {
    final orbState = switch (confidence) {
      >= 0.9 => AiOrbState.confident,
      >= 0.5 => AiOrbState.idle,
      _ => AiOrbState.uncertain,
    };
    emit(
      state.copyWith(
        confidence: confidence.clamp(0, 1),
        uncertainty: uncertainty.clamp(0, 1),
        orbState: orbState,
      ),
    );
  }

  /// Update the Particle Filter emotional state.
  void updateEmotion(String emotion) {
    emit(state.copyWith(emotion: emotion));
  }

  /// Transition the orb to [AiOrbState.thinking] while AI is processing.
  void startThinking() {
    emit(state.copyWith(orbState: AiOrbState.thinking));
  }

  /// Signal that AI finished processing without producing a new block.
  void finishThinking() {
    emit(state.copyWith(orbState: AiOrbState.idle));
  }

  // ── Block management ───────────────────────────────────────────────────────

  /// Append a new [AiBlock] to the companion's block list and notify user.
  void pushBlock(AiBlock block) {
    final updated = [...state.blocks, block];
    final orbState = block is DecisionBlock
        ? AiOrbState.hasSuggestion
        : block is EmotionCheckBlock
        ? AiOrbState.uncertain
        : AiOrbState.idle;
    emit(state.copyWith(blocks: updated, orbState: orbState, hasUnseen: true));
  }

  /// Push multiple blocks at once (stagger delays are set automatically).
  void pushBlocks(List<AiBlock> blocks) {
    for (var block in blocks) {
      pushBlock(block);
    }
  }

  /// Clear all blocks (e.g. when starting a new session).
  void clearBlocks() {
    emit(
      state.copyWith(
        blocks: const [],
        orbState: AiOrbState.idle,
        hasUnseen: false,
      ),
    );
  }

  // ── Sheet visibility ───────────────────────────────────────────────────────

  void openSheet() {
    emit(state.copyWith(isSheetOpen: true, hasUnseen: false));
  }

  void closeSheet() {
    emit(state.copyWith(isSheetOpen: false));
  }

  // ── HITL actions ───────────────────────────────────────────────────────────

  /// User accepted the pending [DecisionBlock] at [blockId].
  void acceptDecision(String blockId) {
    _updateDecisionStatus(blockId, DecisionStatus.accepted);
    emit(state.copyWith(orbState: AiOrbState.confident));
    // Settle back to idle after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) emit(state.copyWith(orbState: AiOrbState.idle));
    });
  }

  /// User rejected the pending [DecisionBlock] at [blockId].
  void rejectDecision(String blockId) {
    _updateDecisionStatus(blockId, DecisionStatus.rejected);
    emit(state.copyWith(orbState: AiOrbState.uncertain));
  }

  /// User modified the pending [DecisionBlock] at [blockId].
  void modifyDecision(String blockId) {
    _updateDecisionStatus(blockId, DecisionStatus.modified);
    emit(state.copyWith(orbState: AiOrbState.uncertain));
  }

  void _updateDecisionStatus(String blockId, DecisionStatus status) {
    final updated = state.blocks.map((b) {
      if (b is DecisionBlock && b.id == blockId) {
        return b.copyWith(status: status);
      }
      return b;
    }).toList();
    emit(state.copyWith(blocks: updated));
  }

  // ── Session lifecycle integration ─────────────────────────────────────────

  /// Call this when a quiz session completes. Generates a DiagnosisInsight +
  /// Decision pair based on the diagnosis snapshot.
  void onSessionComplete({
    required double confidence,
    required double uncertainty,
    required String topicRecommendation,
    required String reason,
    required String duration,
  }) {
    startThinking();
    updateConfidence(confidence, uncertainty: uncertainty);

    final now = DateTime.now();
    final insight = InsightBlock(
      id: 'insight_${now.millisecondsSinceEpoch}',
      timestamp: now,
      delayMs: 0,
      content:
          'Phiên vừa xong cập nhật mô hình AI. Kết quả đã được tính vào lộ trình.',
      confidence: confidence,
      evidenceSource: 'Phiên vừa kết thúc',
      updatedAgo: 'Vừa xong',
    );
    final decision = DecisionBlock(
      id: 'decision_${now.millisecondsSinceEpoch}',
      timestamp: now,
      delayMs: 500,
      recommendation: topicRecommendation,
      reason: reason,
      priority: confidence < 0.6 ? BlockPriority.high : BlockPriority.medium,
      duration: duration,
      actions: const [
        DecisionAction(type: DecisionActionType.accept, label: 'Đồng ý'),
        DecisionAction(type: DecisionActionType.reject, label: 'Không'),
        DecisionAction(type: DecisionActionType.askWhy, label: 'Vì sao?'),
        DecisionAction(type: DecisionActionType.modify, label: 'Chỉnh'),
      ],
    );

    pushBlocks([insight, decision]);
  }

  /// Call when AI detects an emotional shift (slow response, etc.).
  void onEmotionDetected({
    required String message,
    required Map<String, double> probabilities,
    required List<EmotionOption> options,
  }) {
    final block = EmotionCheckBlock(
      id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      delayMs: 0,
      message: message,
      probabilities: probabilities,
      options: options,
    );
    pushBlock(block);
    emit(state.copyWith(orbState: AiOrbState.uncertain));
  }
}
