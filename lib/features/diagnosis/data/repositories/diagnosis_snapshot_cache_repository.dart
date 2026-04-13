import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisSnapshot {
  const DiagnosisSnapshot({
    required this.strengths,
    required this.needsReview,
    required this.nextSuggestedTopic,
    required this.confidenceScore,
    required this.savedAt,
  });

  final List<String> strengths;
  final List<String> needsReview;
  final String nextSuggestedTopic;
  final double confidenceScore;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'strengths': strengths,
      'needsReview': needsReview,
      'nextSuggestedTopic': nextSuggestedTopic,
      'confidenceScore': confidenceScore,
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }

  static DiagnosisSnapshot fromJson(Map<String, dynamic> json) {
    return DiagnosisSnapshot(
      strengths: _toStringList(json['strengths']),
      needsReview: _toStringList(json['needsReview']),
      nextSuggestedTopic: json['nextSuggestedTopic']?.toString() ?? '',
      confidenceScore: _toDouble(json['confidenceScore'], fallback: 0),
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  static List<String> _toStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static double _toDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class DiagnosisSnapshotCacheRepository {
  DiagnosisSnapshotCacheRepository._();

  static final DiagnosisSnapshotCacheRepository instance =
      DiagnosisSnapshotCacheRepository._();

  static const String _snapshotKey = 'latest_diagnosis_snapshot_v1';

  Future<void> saveSnapshot(DiagnosisSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
  }

  Future<DiagnosisSnapshot?> readSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return DiagnosisSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(_snapshotKey);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
  }
}
