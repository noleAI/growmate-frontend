import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/features/diagnosis/data/repositories/diagnosis_snapshot_cache_repository.dart';
import 'package:growmate_frontend/features/session/data/models/session_history_entry.dart';
import 'package:growmate_frontend/features/session/data/repositories/session_history_repository.dart';
import 'package:growmate_frontend/features/session_recovery/data/models/pending_session.dart';
import 'package:growmate_frontend/features/today/presentation/cubit/home_hydration_cubit.dart';
import 'package:growmate_frontend/features/today/presentation/cubit/home_hydration_state.dart';

void main() {
  SessionHistoryEntry buildEntry({
    double focusScore = 3.6,
  }) {
    return SessionHistoryEntry(
      id: 'session_1',
      sourceKey: 'session:1',
      completedAt: DateTime.utc(2026, 4, 18, 10),
      topic: 'Derivatives',
      mode: 'academic',
      durationMinutes: 15,
      focusScore: focusScore,
      confidenceScore: 0.8,
      nextAction: 'Continue with one more practice set.',
    );
  }

  DiagnosisSnapshot buildSnapshot({double confidenceScore = 0.72}) {
    return DiagnosisSnapshot(
      strengths: const <String>['Chain rule'],
      needsReview: const <String>['Limits'],
      nextSuggestedTopic: 'Derivatives',
      confidenceScore: confidenceScore,
      savedAt: DateTime.utc(2026, 4, 18, 10),
    );
  }

  test('hydrates into ready state when remote history is confirmed', () async {
    final cubit = HomeHydrationCubit(
      historyLoader: () async => SessionHistoryLoadResult(
        entries: <SessionHistoryEntry>[buildEntry(focusScore: 3.7)],
        localEntries: const <SessionHistoryEntry>[],
        hasRemoteSourceConfigured: true,
        remoteFetchSucceeded: true,
      ),
      diagnosisSnapshotLoader: () async => buildSnapshot(confidenceScore: 0.67),
      pendingSessionLoader: () async => PendingSession.empty,
    );

    await cubit.hydrate();

    expect(cubit.state.status, HomeHydrationStatus.ready);
    expect(cubit.state.latestSession?.topic, 'Derivatives');
    expect(cubit.state.confidence, 0.67);
    expect(cubit.state.emotion, 'focused');

    await cubit.close();
  });

  test('hydrates into empty state when server confirms no history', () async {
    final cubit = HomeHydrationCubit(
      historyLoader: () async => const SessionHistoryLoadResult(
        entries: <SessionHistoryEntry>[],
        localEntries: <SessionHistoryEntry>[],
        hasRemoteSourceConfigured: true,
        remoteFetchSucceeded: true,
      ),
      diagnosisSnapshotLoader: () async => null,
      pendingSessionLoader: () async => PendingSession.empty,
    );

    await cubit.hydrate();

    expect(cubit.state.status, HomeHydrationStatus.empty);
    expect(cubit.state.history, isEmpty);
    expect(cubit.state.pendingSession, PendingSession.empty);

    await cubit.close();
  });

  test('hydrates into error state when remote confirmation fails', () async {
    final pending = PendingSession(
      hasPending: true,
      sessionId: 'pending_1',
      progressPercent: 40,
    );
    final cubit = HomeHydrationCubit(
      historyLoader: () async => SessionHistoryLoadResult(
        entries: <SessionHistoryEntry>[buildEntry(focusScore: 1.8)],
        localEntries: <SessionHistoryEntry>[buildEntry(focusScore: 1.8)],
        hasRemoteSourceConfigured: true,
        remoteFetchSucceeded: false,
      ),
      diagnosisSnapshotLoader: () async => buildSnapshot(),
      pendingSessionLoader: () async => pending,
    );

    await cubit.hydrate();

    expect(cubit.state.status, HomeHydrationStatus.error);
    expect(cubit.state.history, isEmpty);
    expect(cubit.state.pendingSession, pending);
    expect(cubit.state.errorMessage, isNotEmpty);

    await cubit.close();
  });
}
