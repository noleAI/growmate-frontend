import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../diagnosis/data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../../recovery/data/repositories/session_recovery_local.dart';
import '../../../session/data/models/session_history_entry.dart';
import '../../../session/data/repositories/session_history_repository.dart';
import '../../../session_recovery/data/models/pending_session.dart';
import '../../../session_recovery/data/repositories/session_recovery_repository.dart';
import 'home_hydration_state.dart';

typedef HistoryLoader = Future<SessionHistoryLoadResult> Function();
typedef DiagnosisSnapshotLoader = Future<DiagnosisSnapshot?> Function();
typedef PendingSessionLoader = Future<PendingSession?> Function();

class HomeHydrationCubit extends Cubit<HomeHydrationState> {
  HomeHydrationCubit({
    SessionHistoryRepository? historyRepository,
    DiagnosisSnapshotCacheRepository? diagnosisSnapshotCacheRepository,
    SessionRecoveryRepository? sessionRecoveryRepository,
    HistoryLoader? historyLoader,
    DiagnosisSnapshotLoader? diagnosisSnapshotLoader,
    PendingSessionLoader? pendingSessionLoader,
  }) : _sessionRecoveryRepository = sessionRecoveryRepository,
       _historyLoader = historyLoader ?? historyRepository!.loadHydratedHistory,
       _diagnosisSnapshotLoader =
           diagnosisSnapshotLoader ??
           diagnosisSnapshotCacheRepository!.readSnapshot,
       _pendingSessionLoader = pendingSessionLoader,
       super(HomeHydrationState.initial());

  final SessionRecoveryRepository? _sessionRecoveryRepository;
  final HistoryLoader _historyLoader;
  final DiagnosisSnapshotLoader _diagnosisSnapshotLoader;
  final PendingSessionLoader? _pendingSessionLoader;

  Future<void> hydrate() async {
    emit(HomeHydrationState.initial());

    final historyFuture = _historyLoader();
    final snapshotFuture = _diagnosisSnapshotLoader();
    final pendingFuture = _pendingSessionLoader?.call() ?? _loadPendingSession();

    final historyResult = await historyFuture;
    final diagnosisSnapshot = await snapshotFuture;
    final pendingSession = await pendingFuture;

    final hasRemoteConfigured = historyResult.hasRemoteSourceConfigured;
    final hasRemoteConfirmation = historyResult.isRemoteConfirmed;

    if (hasRemoteConfigured && !historyResult.remoteFetchSucceeded) {
      emit(
        HomeHydrationState(
          status: HomeHydrationStatus.error,
          history: const <SessionHistoryEntry>[],
          confidence: 0,
          emotion: _resolveEmotion(null),
          pendingSession: pendingSession,
          diagnosisSnapshot: diagnosisSnapshot,
          errorMessage:
              'Unable to confirm your latest study data from the server.',
          hasRemoteHistoryConfigured: hasRemoteConfigured,
          hasRemoteHistoryConfirmation: hasRemoteConfirmation,
        ),
      );
      return;
    }

    final history = historyResult.entries;
    final latestSession = history.isEmpty ? null : history.first;
    final confidence = diagnosisSnapshot?.confidenceScore.clamp(0.0, 1.0) ?? 0.0;
    final status = latestSession == null
        ? HomeHydrationStatus.empty
        : HomeHydrationStatus.ready;

    emit(
      HomeHydrationState(
        status: status,
        history: history,
        confidence: confidence,
        emotion: _resolveEmotion(latestSession),
        pendingSession: pendingSession,
        diagnosisSnapshot: diagnosisSnapshot,
        hasRemoteHistoryConfigured: hasRemoteConfigured,
        hasRemoteHistoryConfirmation: hasRemoteConfirmation,
      ),
    );
  }

  Future<void> refresh() => hydrate();

  String _resolveEmotion(SessionHistoryEntry? latestSession) {
    if (latestSession == null) {
      return 'focused';
    }

    final focus = latestSession.focusScore;
    if (focus < 2.0) {
      return 'exhausted';
    }
    if (focus < 3.0) {
      return 'confused';
    }
    return 'focused';
  }

  Future<PendingSession?> _loadPendingSession() async {
    final repo = _sessionRecoveryRepository;
    if (repo != null) {
      try {
        final pending = await repo.getPendingSession();
        if (pending.hasPending) {
          return pending;
        }
        await SessionRecoveryLocal.clear();
        return null;
      } catch (_) {
        // Fall through to validated local snapshot.
      }
    }

    final localFallback = await SessionRecoveryLocal.loadFreshSnapshot();
    if (localFallback == null) {
      return null;
    }

    return PendingSession(
      hasPending: true,
      sessionId: localFallback.sessionId,
      status: localFallback.status,
      lastQuestionIndex: localFallback.lastQuestionIndex,
      nextQuestionIndex: localFallback.lastQuestionIndex,
      totalQuestions: localFallback.totalQuestions,
      progressPercent: localFallback.totalQuestions > 0
          ? (((localFallback.lastQuestionIndex + 1) /
                        localFallback.totalQuestions) *
                    100)
                .clamp(0, 100)
                .toInt()
          : null,
      mode: 'academic',
      pauseState: false,
      pauseReason: null,
      resumeContextVersion: 1,
      lastActiveAt: localFallback.updatedAt,
      abandonedAt: null,
    );
  }
}
