/// Visual states the AI Orb can be in.
enum AiOrbState {
  /// Default resting state – subtle breathing animation.
  idle,

  /// AI is processing / analysing – radiating pulse rings.
  thinking,

  /// AI has a pending suggestion – glowing halo + notification dot.
  hasSuggestion,

  /// AI is uncertain and wants user input – amber wobble.
  uncertain,

  /// AI just made a confident decision – brief celebratory pulse.
  confident,

  /// Something went wrong – red border, no animation.
  error,
}
