import '../../../shared/widgets/ai_blocks/ai_block_model.dart';
import '../../../shared/widgets/ai_orb/ai_orb_state.dart';

/// State for [AiCompanionCubit].
///
/// Holds the ordered list of structured AI blocks, current orb visual state,
/// confidence/uncertainty, detected emotion, and sheet visibility.
class AiCompanionState {
  const AiCompanionState({
    this.blocks = const [],
    this.orbState = AiOrbState.idle,
    this.confidence = 0.0,
    this.uncertainty = 0.0,
    this.emotion = 'focused',
    this.isSheetOpen = false,
    this.hasUnseen = false,
  });

  final List<AiBlock> blocks;
  final AiOrbState orbState;
  final double confidence;
  final double uncertainty;

  /// Particle Filter detected emotion: 'focused' | 'confused' | 'exhausted' | 'frustrated'
  final String emotion;

  final bool isSheetOpen;

  /// True when AI has a new block the user hasn't seen yet.
  final bool hasUnseen;

  AiCompanionState copyWith({
    List<AiBlock>? blocks,
    AiOrbState? orbState,
    double? confidence,
    double? uncertainty,
    String? emotion,
    bool? isSheetOpen,
    bool? hasUnseen,
  }) {
    return AiCompanionState(
      blocks: blocks ?? this.blocks,
      orbState: orbState ?? this.orbState,
      confidence: confidence ?? this.confidence,
      uncertainty: uncertainty ?? this.uncertainty,
      emotion: emotion ?? this.emotion,
      isSheetOpen: isSheetOpen ?? this.isSheetOpen,
      hasUnseen: hasUnseen ?? this.hasUnseen,
    );
  }
}
