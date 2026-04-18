import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalPendingSession {
  const LocalPendingSession({
    required this.sessionId,
    required this.updatedAt,
    required this.lastQuestionIndex,
    required this.totalQuestions,
    required this.status,
  });

  final String sessionId;
  final DateTime updatedAt;
  final int lastQuestionIndex;
  final int totalQuestions;
  final String status;

  bool get hasRealProgressMetadata =>
      sessionId.trim().isNotEmpty &&
      totalQuestions > 0 &&
      lastQuestionIndex >= 0 &&
      lastQuestionIndex < totalQuestions;

  bool isFresh({Duration maxAge = const Duration(hours: 24)}) {
    final age = DateTime.now().toUtc().difference(updatedAt.toUtc());
    return !age.isNegative && age <= maxAge;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'lastQuestionIndex': lastQuestionIndex,
      'totalQuestions': totalQuestions,
      'status': status,
    };
  }

  factory LocalPendingSession.fromJson(Map<String, dynamic> json) {
    final sessionId = (json['sessionId'] ?? json['session_id'] ?? '')
        .toString();
    final updatedAtRaw = (json['updatedAt'] ?? json['updated_at'] ?? '')
        .toString();
    final updatedAt =
        DateTime.tryParse(updatedAtRaw)?.toUtc() ?? DateTime.now().toUtc();

    final rawLastQuestionIndex =
        json['lastQuestionIndex'] ?? json['last_question_index'];
    final rawTotalQuestions =
        json['totalQuestions'] ??
        json['total_questions'] ??
        json['questionCount'];
    final rawStatus = json['status']?.toString() ?? 'in_progress';

    return LocalPendingSession(
      sessionId: sessionId,
      updatedAt: updatedAt,
      lastQuestionIndex: _safeInt(rawLastQuestionIndex, fallback: 0),
      totalQuestions: _safeInt(rawTotalQuestions, fallback: 0),
      status: rawStatus,
    );
  }
}

/// Local SharedPreferences store for a pending (in-progress) quiz session.
///
/// Saves enough info to allow the user to resume: topicId, questionIndex,
/// answers so far, and timestamp.
class SessionRecoveryLocal {
  static const _key = 'pending_session';

  static const Duration maxFreshAge = Duration(hours: 24);

  /// Save a pending session. [data] should be JSON-serialisable.
  static Future<void> save(Map<String, dynamic> data) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final enriched = <String, dynamic>{
      ...data,
      'updatedAt': data['updatedAt'] ?? now,
      'status': data['status'] ?? 'in_progress',
      'lastQuestionIndex': _safeInt(data['lastQuestionIndex'], fallback: 0),
      'totalQuestions': _safeInt(
        data['totalQuestions'] ?? data['questionCount'],
        fallback: 0,
      ),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(enriched));
  }

  static Future<void> saveSnapshot({
    required String sessionId,
    required int lastQuestionIndex,
    required int totalQuestions,
    required String status,
    DateTime? updatedAt,
  }) async {
    final payload = LocalPendingSession(
      sessionId: sessionId,
      updatedAt: updatedAt?.toUtc() ?? DateTime.now().toUtc(),
      lastQuestionIndex: lastQuestionIndex,
      totalQuestions: totalQuestions,
      status: status,
    );

    await save(payload.toJson());
  }

  /// Load the pending session, or null if none exists.
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<LocalPendingSession?> loadSnapshot() async {
    final payload = await load();
    if (payload == null) {
      return null;
    }

    try {
      return LocalPendingSession.fromJson(payload);
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<LocalPendingSession?> loadFreshSnapshot({
    Duration maxAge = maxFreshAge,
  }) async {
    final snapshot = await loadSnapshot();
    if (snapshot == null) {
      return null;
    }

    if (!snapshot.isFresh(maxAge: maxAge) ||
        !snapshot.hasRealProgressMetadata) {
      await clear();
      return null;
    }

    return snapshot;
  }

  /// Delete the pending session (call after completing or abandoning).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns true if there is a pending session saved.
  static Future<bool> hasPending() async {
    return (await loadSnapshot()) != null;
  }
}

int _safeInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
