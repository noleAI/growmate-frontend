import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_history_entry.dart';

class SessionHistoryRepository {
  SessionHistoryRepository._();

  static final SessionHistoryRepository instance = SessionHistoryRepository._();

  static const String _historyKey = 'session_history_v1';

  final StreamController<List<SessionHistoryEntry>> _controller =
      StreamController<List<SessionHistoryEntry>>.broadcast();

  Stream<List<SessionHistoryEntry>> watchHistory() async* {
    final snapshot = await getHistory();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<List<SessionHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);

    if (raw == null || raw.isEmpty) {
      return <SessionHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <SessionHistoryEntry>[];
      }

      final entries =
          decoded
              .whereType<Map>()
              .map(
                (item) => SessionHistoryEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      return entries;
    } catch (_) {
      await prefs.remove(_historyKey);
      return <SessionHistoryEntry>[];
    }
  }

  Future<SessionHistoryEntry> upsertCompletedSession({
    required String sourceKey,
    required String topic,
    required String mode,
    required int durationMinutes,
    required double focusScore,
    required double confidenceScore,
    required String nextAction,
    DateTime? completedAt,
  }) async {
    final current = await getHistory();
    final index = current.indexWhere((entry) => entry.sourceKey == sourceKey);

    final normalized = SessionHistoryEntry(
      id: index >= 0
          ? current[index].id
          : 's_${DateTime.now().microsecondsSinceEpoch}',
      sourceKey: sourceKey,
      completedAt: (completedAt ?? DateTime.now()).toUtc(),
      topic: topic,
      mode: mode,
      durationMinutes: durationMinutes,
      focusScore: focusScore.clamp(0.0, 4.0),
      confidenceScore: confidenceScore.clamp(0.0, 1.0),
      nextAction: nextAction,
    );

    final mutable = List<SessionHistoryEntry>.from(current);
    if (index >= 0) {
      mutable[index] = normalized;
    } else {
      mutable.add(normalized);
    }

    mutable.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await _persist(mutable);
    return normalized;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    _controller.add(<SessionHistoryEntry>[]);
  }

  Future<void> _persist(List<SessionHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await prefs.setString(_historyKey, raw);
    _controller.add(entries);
  }
}
