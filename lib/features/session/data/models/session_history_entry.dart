class SessionHistoryEntry {
  const SessionHistoryEntry({
    required this.id,
    required this.sourceKey,
    required this.completedAt,
    required this.topic,
    required this.mode,
    required this.durationMinutes,
    required this.focusScore,
    required this.confidenceScore,
    required this.nextAction,
  });

  final String id;
  final String sourceKey;
  final DateTime completedAt;
  final String topic;
  final String mode;
  final int durationMinutes;
  final double focusScore;
  final double confidenceScore;
  final String nextAction;

  SessionHistoryEntry copyWith({
    String? id,
    String? sourceKey,
    DateTime? completedAt,
    String? topic,
    String? mode,
    int? durationMinutes,
    double? focusScore,
    double? confidenceScore,
    String? nextAction,
  }) {
    return SessionHistoryEntry(
      id: id ?? this.id,
      sourceKey: sourceKey ?? this.sourceKey,
      completedAt: completedAt ?? this.completedAt,
      topic: topic ?? this.topic,
      mode: mode ?? this.mode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focusScore: focusScore ?? this.focusScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      nextAction: nextAction ?? this.nextAction,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceKey': sourceKey,
      'completedAt': completedAt.toUtc().toIso8601String(),
      'topic': topic,
      'mode': mode,
      'durationMinutes': durationMinutes,
      'focusScore': focusScore,
      'confidenceScore': confidenceScore,
      'nextAction': nextAction,
    };
  }

  static SessionHistoryEntry fromJson(Map<String, dynamic> json) {
    return SessionHistoryEntry(
      id: json['id']?.toString() ?? '',
      sourceKey: json['sourceKey']?.toString() ?? '',
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      topic: json['topic']?.toString() ?? 'Review Đạo hàm',
      mode: json['mode']?.toString() ?? 'academic',
      durationMinutes: _safeInt(json['durationMinutes'], fallback: 12),
      focusScore: _safeDouble(json['focusScore'], fallback: 3.0),
      confidenceScore: _safeDouble(json['confidenceScore'], fallback: 0.78),
      nextAction:
          json['nextAction']?.toString() ??
          'Ôn 3 câu nhẹ trước khi vào bài mới',
    );
  }

  static int _safeInt(Object? value, {required int fallback}) {
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

  static double _safeDouble(Object? value, {required double fallback}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
