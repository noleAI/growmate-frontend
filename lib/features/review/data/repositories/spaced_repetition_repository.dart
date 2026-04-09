import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/spaced_review_item.dart';

class SpacedRepetitionRepository {
  SpacedRepetitionRepository._();

  static final SpacedRepetitionRepository instance =
      SpacedRepetitionRepository._();

  static const String _storageKey = 'spaced_repetition_items_v1';

  final StreamController<List<SpacedReviewItem>> _controller =
      StreamController<List<SpacedReviewItem>>.broadcast();

  Stream<List<SpacedReviewItem>> watchItems() async* {
    final snapshot = await getItems();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<List<SpacedReviewItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <SpacedReviewItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <SpacedReviewItem>[];
      }

      final items =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    SpacedReviewItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
            ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

      return items;
    } catch (_) {
      await prefs.remove(_storageKey);
      return <SpacedReviewItem>[];
    }
  }

  Future<List<SpacedReviewItem>> getDueItems({DateTime? now}) async {
    final snapshot = await getItems();
    final reference = (now ?? DateTime.now()).toUtc();

    return snapshot
        .where((item) => !item.dueAt.isAfter(reference))
        .toList(growable: false)
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  Future<SpacedReviewItem> registerStudySession({
    required String topic,
    required double focusScore,
    required String sourceKey,
    DateTime? completedAt,
  }) async {
    final normalizedTopic = topic.trim();
    if (normalizedTopic.isEmpty) {
      throw ArgumentError('topic must not be empty');
    }

    final reference = (completedAt ?? DateTime.now()).toUtc();
    final quality = _qualityFromFocus(focusScore);

    final items = await getItems();
    final index = items.indexWhere(
      (item) => item.topic.toLowerCase() == normalizedTopic.toLowerCase(),
    );

    final current = index >= 0 ? items[index] : null;
    final next = _nextItem(
      topic: normalizedTopic,
      sourceKey: sourceKey,
      current: current,
      quality: quality,
      reviewedAt: reference,
    );

    final mutable = List<SpacedReviewItem>.from(items);
    if (index >= 0) {
      mutable[index] = next;
    } else {
      mutable.add(next);
    }

    mutable.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await _persist(mutable);
    return next;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _controller.add(<SpacedReviewItem>[]);
  }

  SpacedReviewItem _nextItem({
    required String topic,
    required String sourceKey,
    required SpacedReviewItem? current,
    required int quality,
    required DateTime reviewedAt,
  }) {
    var repetitions = current?.repetitions ?? 0;
    var intervalDays = current?.intervalDays ?? 1;
    var easeFactor = current?.easeFactor ?? 2.5;

    if (quality < 3) {
      repetitions = 0;
      intervalDays = 1;
    } else {
      repetitions += 1;
      if (repetitions == 1) {
        intervalDays = 1;
      } else if (repetitions == 2) {
        intervalDays = 3;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
        intervalDays = intervalDays.clamp(4, 120);
      }
    }

    easeFactor = math.max(
      1.3,
      easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)),
    );

    final dueAt = reviewedAt.add(Duration(days: intervalDays));

    return SpacedReviewItem(
      id: current?.id ?? 'sr_${DateTime.now().microsecondsSinceEpoch}',
      topic: topic,
      dueAt: dueAt,
      intervalDays: intervalDays,
      repetitions: repetitions,
      easeFactor: easeFactor,
      lastReviewedAt: reviewedAt,
      sourceKey: sourceKey,
    );
  }

  static int _qualityFromFocus(double focusScore) {
    if (focusScore >= 3.6) {
      return 5;
    }
    if (focusScore >= 3.2) {
      return 4;
    }
    if (focusScore >= 2.8) {
      return 3;
    }
    if (focusScore >= 2.2) {
      return 2;
    }
    return 1;
  }

  Future<void> _persist(List<SpacedReviewItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );

    await prefs.setString(_storageKey, raw);
    _controller.add(items);
  }
}
