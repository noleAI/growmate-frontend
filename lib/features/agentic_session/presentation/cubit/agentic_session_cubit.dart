import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/agentic_models.dart';
import '../../data/repositories/agentic_session_repository.dart';
import 'agentic_session_state.dart';

/// Cubit managing the agentic learning session lifecycle.
///
/// Controls the full flow:
/// ```
/// idle → startSession → ready → submitAnswer → processing → interacting
///                                                    ↑            ↓
///                                            (loop: quiz → orchestrator → UI)
///                                                    ↓
///                                             hitlPending / recovery
///                                                    ↓
///                                                completed
/// ```
///
/// Listens to real-time WebSocket streams for:
/// - Dashboard updates (academic, empathy, strategy states)
/// - Behavior events (intervention_proposed, hitl_triggered)
class AgenticSessionCubit extends Cubit<AgenticSessionState> {
  AgenticSessionCubit({required AgenticSessionRepository repository})
    : _repo = repository,
      super(AgenticSessionState.initial());

  final AgenticSessionRepository _repo;

  StreamSubscription<DashboardUpdate>? _dashboardSub;
  StreamSubscription<BehaviorWsEvent>? _behaviorSub;

  // ─── Session Lifecycle ─────────────────────────────────────────────────

  /// Starts a new agentic session for the given subject/topic.
  ///
  /// Opens WebSocket channels and transitions to [AgenticPhase.ready].
  Future<void> startSession({
    required String subject,
    required String topic,
  }) async {
    emit(
      state.copyWith(
        phase: AgenticPhase.processing,
        subject: subject,
        topic: topic,
      ),
    );

    try {
      final response = await _repo.startSession(subject: subject, topic: topic);

      // Start listening to real-time streams
      _subscribeToDashboard();
      _subscribeToBehaviorEvents();

      emit(
        state.copyWith(
          phase: AgenticPhase.ready,
          sessionId: response.sessionId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: AgenticPhase.error,
          errorMessage: 'Không thể bắt đầu phiên học: $e',
        ),
      );
    }
  }

  /// Ends the current session.
  Future<void> endSession({String status = 'completed'}) async {
    _cancelSubscriptions();

    try {
      await _repo.endSession(status: status);
    } catch (e) {
      _log('End session error: $e');
    }

    emit(AgenticSessionState.initial().copyWith(phase: AgenticPhase.completed));
  }

  // ─── Quiz Interaction ──────────────────────────────────────────────────

  /// Submits a quiz answer and waits for the orchestrator response.
  ///
  /// The response determines the next node: hint, drill, next_question,
  /// backtrack_repair, de_stress, recovery, hitl_pending, etc.
  Future<void> submitAnswer({
    required String questionId,
    required Map<String, dynamic> responseData,
  }) async {
    emit(state.copyWith(phase: AgenticPhase.processing));

    try {
      final response = await _repo.submitAnswer(
        questionId: questionId,
        responseData: responseData,
      );

      _handleInteractionResponse(response);
    } catch (e) {
      emit(
        state.copyWith(
          phase: AgenticPhase.error,
          errorMessage: 'Lỗi khi gửi câu trả lời: $e',
        ),
      );
    }
  }

  /// Sends a generic interaction (feedback, skip, navigate, etc.)
  Future<void> sendInteraction({
    required String actionType,
    String? quizId,
    Map<String, dynamic>? responseData,
  }) async {
    emit(state.copyWith(phase: AgenticPhase.processing));

    try {
      final response = await _repo.sendInteraction(
        actionType: actionType,
        quizId: quizId,
        responseData: responseData,
      );

      _handleInteractionResponse(response);
    } catch (e) {
      emit(
        state.copyWith(
          phase: AgenticPhase.error,
          errorMessage: 'Lỗi khi gửi tương tác: $e',
        ),
      );
    }
  }

  /// Runs a full orchestrator step to get data-driven diagnosis
  /// and intervention plans.
  Future<void> runFullStep({
    String? questionId,
    Map<String, dynamic>? response,
    Map<String, dynamic>? behaviorSignals,
  }) async {
    emit(state.copyWith(phase: AgenticPhase.processing));

    try {
      final result = await _repo.runOrchestratorStep(
        questionId: questionId,
        response: response,
        behaviorSignals: behaviorSignals,
      );

      final nextPhase = _phaseFromAction(result.action);

      emit(
        state.copyWith(
          phase: nextPhase,
          lastOrchestratorStep: result,
          currentAction: result.action,
          currentContent: result.payload.text,
          latestDashboard: result.dashboardUpdate,
          stepCount: state.stepCount + 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: AgenticPhase.error,
          errorMessage: 'Lỗi khi chạy orchestrator: $e',
        ),
      );
    }
  }

  // ─── Behavioral Signals ────────────────────────────────────────────────

  /// Sends behavioral signals to the Particle Filter in real-time.
  void sendBehaviorSignal({
    required double typingSpeed,
    required double idleTime,
    required double correctionRate,
    double? responseTime,
  }) {
    if (!_repo.hasActiveSession) return;

    _repo.sendBehaviorSignal(
      typingSpeed: typingSpeed,
      idleTime: idleTime,
      correctionRate: correctionRate,
      responseTime: responseTime,
    );
  }

  // ─── Error Recovery ────────────────────────────────────────────────────

  /// Clears error state and returns to the last valid phase.
  void clearError() {
    if (state.hasError) {
      final fallbackPhase = state.sessionId != null
          ? AgenticPhase.interacting
          : AgenticPhase.idle;
      emit(state.copyWith(phase: fallbackPhase, errorMessage: null));
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  void _handleInteractionResponse(AgenticInteractionResponse response) {
    final nextPhase = _phaseFromAction(response.nextNodeType);

    emit(
      state.copyWith(
        phase: nextPhase,
        lastInteraction: response,
        currentAction: response.nextNodeType,
        currentContent: response.content,
        beliefEntropy: response.beliefEntropy,
        planRepaired: response.planRepaired,
        stepCount: state.stepCount + 1,
      ),
    );
  }

  AgenticPhase _phaseFromAction(String action) {
    switch (action) {
      case 'hitl_pending':
      case 'hitl':
        return AgenticPhase.hitlPending;
      case 'de_stress':
      case 'recovery':
      case 'suggest_break':
        return AgenticPhase.recovery;
      default:
        return AgenticPhase.interacting;
    }
  }

  void _subscribeToDashboard() {
    _dashboardSub?.cancel();
    _dashboardSub = _repo.dashboardUpdates.listen((update) {
      // Update state with latest dashboard data without changing phase
      final nextPhase = update.hitlPending
          ? AgenticPhase.hitlPending
          : state.phase;

      emit(state.copyWith(latestDashboard: update, phase: nextPhase));
    });
  }

  void _subscribeToBehaviorEvents() {
    _behaviorSub?.cancel();
    _behaviorSub = _repo.behaviorEvents.listen((event) {
      if (event.isInterventionProposed) {
        emit(state.copyWith(phase: AgenticPhase.recovery));
      } else if (event.isHitlTriggered) {
        emit(state.copyWith(phase: AgenticPhase.hitlPending));
      }
    });
  }

  void _cancelSubscriptions() {
    _dashboardSub?.cancel();
    _dashboardSub = null;
    _behaviorSub?.cancel();
    _behaviorSub = null;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('🤖 [AgenticCubit] $message');
  }

  @override
  Future<void> close() async {
    _cancelSubscriptions();
    return super.close();
  }
}
