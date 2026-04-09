class OfflineState {
  const OfflineState({
    required this.enabled,
    required this.queuedSignals,
    required this.lastSyncedAt,
  });

  final bool enabled;
  final int queuedSignals;
  final DateTime? lastSyncedAt;

  OfflineState copyWith({
    bool? enabled,
    int? queuedSignals,
    DateTime? lastSyncedAt,
  }) {
    return OfflineState(
      enabled: enabled ?? this.enabled,
      queuedSignals: queuedSignals ?? this.queuedSignals,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
