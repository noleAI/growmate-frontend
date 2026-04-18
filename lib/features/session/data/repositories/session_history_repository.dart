import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../quiz/data/models/quiz_api_models.dart';
import '../../../quiz/data/repositories/quiz_api_repository.dart';
import '../models/session_history_entry.dart';

class SessionHistoryLoadResult {
  const SessionHistoryLoadResult({
    required this.entries,
    required this.localEntries,
    required this.hasRemoteSourceConfigured,
    required this.remoteFetchSucceeded,
  });

  final List<SessionHistoryEntry> entries;
  final List<SessionHistoryEntry> localEntries;
  final bool hasRemoteSourceConfigured;
  final bool remoteFetchSucceeded;

  bool get isRemoteConfirmed =>
      !hasRemoteSourceConfigured || remoteFetchSucceeded;
}

class SessionHistoryRepository {
  SessionHistoryRepository._();

  static final SessionHistoryRepository instance = SessionHistoryRepository._();

  static const String _historyKey = 'session_history_v1';

  final StreamController<List<SessionHistoryEntry>> _controller =
      StreamController<List<SessionHistoryEntry>>.broadcast();
  QuizApiRepository? _quizApiRepository;

  bool get hasRemoteSourceConfigured => _quizApiRepository != null;

  void configure({QuizApiRepository? quizApiRepository}) {
    _quizApiRepository = quizApiRepository;
    unawaited(_emitSnapshot());
  }

  Stream<List<SessionHistoryEntry>> watchHistory() async* {
    final snapshot = await getHistory();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<List<SessionHistoryEntry>> getHistory() async {
    final result = await loadHydratedHistory();
    return result.entries;
  }

  Future<SessionHistoryLoadResult> loadHydratedHistory() async {
    final localEntries = await _readLocalHistory();
    final quizApiRepository = _quizApiRepository;
    if (quizApiRepository == null) {
      return SessionHistoryLoadResult(
        entries: localEntries,
        localEntries: localEntries,
        hasRemoteSourceConfigured: false,
        remoteFetchSucceeded: false,
      );
    }

    try {
      final remoteEntries = await _fetchRemoteHistory(quizApiRepository);
      return SessionHistoryLoadResult(
        entries: _mergeHistory(remoteEntries, localEntries),
        localEntries: localEntries,
        hasRemoteSourceConfigured: true,
        remoteFetchSucceeded: true,
      );
    } catch (_) {
      return SessionHistoryLoadResult(
        entries: localEntries,
        localEntries: localEntries,
        hasRemoteSourceConfigured: true,
        remoteFetchSucceeded: false,
      );
    }
  }

  Future<List<SessionHistoryEntry>> _readLocalHistory() async {
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
    final current = await _readLocalHistory();
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
    await _persistLocal(mutable);
    return normalized;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await _emitSnapshot();
  }

  Future<void> _persistLocal(List<SessionHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await prefs.setString(_historyKey, raw);
    await _emitSnapshot();
  }

  Future<void> _emitSnapshot() async {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(await getHistory());
  }

  Future<List<SessionHistoryEntry>> _fetchRemoteHistory(
    QuizApiRepository quizApiRepository,
  ) async {
    final response = await quizApiRepository.getQuizHistory(
      limit: 50,
      offset: 0,
    );
    return response.items.map(_mapRemoteHistoryItem).toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<SessionHistoryEntry> _mergeHistory(
    List<SessionHistoryEntry> remoteEntries,
    List<SessionHistoryEntry> localEntries,
  ) {
    final merged = <String, SessionHistoryEntry>{};

    for (final entry in remoteEntries) {
      merged[_mergeKey(entry)] = entry;
    }
    for (final entry in localEntries) {
      merged[_mergeKey(entry)] = entry;
    }

    final entries = merged.values.toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return entries;
  }

  SessionHistoryEntry _mapRemoteHistoryItem(QuizHistoryItem item) {
    final confidence = (item.summary.accuracyPercent / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final sessionId = item.sessionId.trim();

    return SessionHistoryEntry(
      id: 'remote_$sessionId',
      sourceKey: 'session:$sessionId',
      completedAt: (item.endTime ?? item.startTime ?? DateTime.now()).toUtc(),
      topic: _historyTopicLabel(sessionId),
      mode: item.status.toLowerCase() == 'abandoned' ? 'recovery' : 'academic',
      durationMinutes: _historyDurationMinutes(item.summary.answeredCount),
      focusScore: (confidence * 4).clamp(0.0, 4.0).toDouble(),
      confidenceScore: confidence,
      nextAction: _historyNextAction(confidence),
    );
  }

  String _mergeKey(SessionHistoryEntry entry) {
    return _extractSessionId(entry.sourceKey) ?? entry.sourceKey.trim();
  }

  String? _extractSessionId(String sourceKey) {
    final trimmed = sourceKey.trim();
    if (trimmed.startsWith('session:')) {
      final value = trimmed.substring('session:'.length).trim();
      return value.isEmpty ? null : value;
    }
    if (trimmed.startsWith('submission:')) {
      final segments = trimmed.split('|');
      if (segments.isEmpty) {
        return null;
      }
      final value = segments.first.substring('submission:'.length).trim();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  String _historyTopicLabel(String sessionId) {
    final suffix = sessionId.length > 8
        ? sessionId.substring(sessionId.length - 8)
        : sessionId;
    return 'Phiên quiz #$suffix';
  }

  int _historyDurationMinutes(int answeredCount) {
    final estimated = answeredCount <= 0 ? 8 : answeredCount * 2;
    return estimated.clamp(5, 120).toInt();
  }

  String _historyNextAction(double confidence) {
    if (confidence >= 0.85) {
      return 'Tăng nhẹ độ khó ở phiên kế tiếp';
    }
    if (confidence >= 0.6) {
      return 'Ôn lại nhóm câu sai và làm thêm 2 câu tương tự';
    }
    return 'Ôn lại lý thuyết cốt lõi trước khi tiếp tục';
  }
}
