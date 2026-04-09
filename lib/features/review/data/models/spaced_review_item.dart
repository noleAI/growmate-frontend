class SpacedReviewItem {
  const SpacedReviewItem({
    required this.id,
    required this.topic,
    required this.dueAt,
    required this.intervalDays,
    required this.repetitions,
    required this.easeFactor,
    required this.lastReviewedAt,
    required this.sourceKey,
  });

  final String id;
  final String topic;
  final DateTime dueAt;
  final int intervalDays;
  final int repetitions;
  final double easeFactor;
  final DateTime lastReviewedAt;
  final String sourceKey;

  SpacedReviewItem copyWith({
    String? id,
    String? topic,
    DateTime? dueAt,
    int? intervalDays,
    int? repetitions,
    double? easeFactor,
    DateTime? lastReviewedAt,
    String? sourceKey,
  }) {
    return SpacedReviewItem(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      sourceKey: sourceKey ?? this.sourceKey,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'topic': topic,
      'dueAt': dueAt.toUtc().toIso8601String(),
      'intervalDays': intervalDays,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'lastReviewedAt': lastReviewedAt.toUtc().toIso8601String(),
      'sourceKey': sourceKey,
    };
  }

  static SpacedReviewItem fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();

    return SpacedReviewItem(
      id: json['id']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'Review nhanh',
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? '')?.toUtc() ?? now,
      intervalDays: _safeInt(json['intervalDays'], fallback: 1),
      repetitions: _safeInt(json['repetitions'], fallback: 0),
      easeFactor: _safeDouble(json['easeFactor'], fallback: 2.5),
      lastReviewedAt:
          DateTime.tryParse(
            json['lastReviewedAt']?.toString() ?? '',
          )?.toUtc() ??
          now,
      sourceKey: json['sourceKey']?.toString() ?? 'manual',
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
