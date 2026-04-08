import 'package:equatable/equatable.dart';

import 'intervention_state.dart';

sealed class InterventionEvent extends Equatable {
  const InterventionEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class InterventionStarted extends InterventionEvent {
  const InterventionStarted();
}

final class InterventionOptionSelected extends InterventionEvent {
  const InterventionOptionSelected(this.option);

  final InterventionOption option;

  @override
  List<Object?> get props => <Object?>[option];
}

final class InterventionPromptResolved extends InterventionEvent {
  const InterventionPromptResolved({required this.chooseRecovery});

  final bool chooseRecovery;

  @override
  List<Object?> get props => <Object?>[chooseRecovery];
}

final class InterventionMessageCleared extends InterventionEvent {
  const InterventionMessageCleared();
}

final class RecoveryTicked extends InterventionEvent {
  const RecoveryTicked();
}
