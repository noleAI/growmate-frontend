import 'package:equatable/equatable.dart';

import '../../../diagnosis/data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../../session/data/models/session_history_entry.dart';
import '../../../session_recovery/data/models/pending_session.dart';

enum HomeHydrationStatus { loading, ready, empty, error }

class HomeHydrationState extends Equatable {
  const HomeHydrationState({
    required this.status,
    this.history = const <SessionHistoryEntry>[],
    this.confidence = 0,
    this.emotion = 'focused',
    this.pendingSession,
    this.diagnosisSnapshot,
    this.errorMessage,
    this.hasRemoteHistoryConfigured = false,
    this.hasRemoteHistoryConfirmation = false,
  });

  final HomeHydrationStatus status;
  final List<SessionHistoryEntry> history;
  final double confidence;
  final String emotion;
  final PendingSession? pendingSession;
  final DiagnosisSnapshot? diagnosisSnapshot;
  final String? errorMessage;
  final bool hasRemoteHistoryConfigured;
  final bool hasRemoteHistoryConfirmation;

  SessionHistoryEntry? get latestSession => history.isEmpty ? null : history.first;

  bool get hasReadyHistory =>
      status == HomeHydrationStatus.ready && latestSession != null;

  bool get showEmptyOnboarding =>
      status == HomeHydrationStatus.empty && history.isEmpty;

  factory HomeHydrationState.initial() {
    return const HomeHydrationState(status: HomeHydrationStatus.loading);
  }

  HomeHydrationState copyWith({
    HomeHydrationStatus? status,
    List<SessionHistoryEntry>? history,
    double? confidence,
    String? emotion,
    PendingSession? pendingSession,
    DiagnosisSnapshot? diagnosisSnapshot,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? hasRemoteHistoryConfigured,
    bool? hasRemoteHistoryConfirmation,
  }) {
    return HomeHydrationState(
      status: status ?? this.status,
      history: history ?? this.history,
      confidence: confidence ?? this.confidence,
      emotion: emotion ?? this.emotion,
      pendingSession: pendingSession ?? this.pendingSession,
      diagnosisSnapshot: diagnosisSnapshot ?? this.diagnosisSnapshot,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      hasRemoteHistoryConfigured:
          hasRemoteHistoryConfigured ?? this.hasRemoteHistoryConfigured,
      hasRemoteHistoryConfirmation:
          hasRemoteHistoryConfirmation ?? this.hasRemoteHistoryConfirmation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    confidence,
    emotion,
    pendingSession,
    diagnosisSnapshot,
    errorMessage,
    hasRemoteHistoryConfigured,
    hasRemoteHistoryConfirmation,
  ];
}
