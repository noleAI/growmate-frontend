import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_schedule_item.dart';

class StudyScheduleRepository {
  StudyScheduleRepository._();

  static final StudyScheduleRepository instance = StudyScheduleRepository._();

  static const String _storageKey = 'study_schedule_items_v1';

  final StreamController<List<StudyScheduleItem>> _controller =
      StreamController<List<StudyScheduleItem>>.broadcast();

  Stream<List<StudyScheduleItem>> watchItems() async* {
    final snapshot = await getItems();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<List<StudyScheduleItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <StudyScheduleItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <StudyScheduleItem>[];
      }

      final items =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    StudyScheduleItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
            ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

      return items;
    } catch (_) {
      await prefs.remove(_storageKey);
      return <StudyScheduleItem>[];
    }
  }

  Future<StudyScheduleItem> upsertItem({
    String? id,
    required String title,
    required String subject,
    required DateTime dueAt,
    required String type,
    int priority = 2,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }

    final items = await getItems();
    final targetId = id?.trim();
    final index = targetId == null || targetId.isEmpty
        ? -1
        : items.indexWhere((item) => item.id == targetId);

    final current = index >= 0 ? items[index] : null;

    final next = StudyScheduleItem(
      id: current?.id ?? 'sch_${DateTime.now().microsecondsSinceEpoch}',
      title: normalizedTitle,
      subject: subject.trim().isEmpty ? 'Tổng hợp' : subject.trim(),
      dueAt: dueAt.toUtc(),
      type: type.trim().isEmpty ? 'deadline' : type.trim(),
      priority: priority.clamp(1, 3),
      completed: current?.completed ?? false,
    );

    final mutable = List<StudyScheduleItem>.from(items);
    if (index >= 0) {
      mutable[index] = next;
    } else {
      mutable.add(next);
    }

    mutable.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await _persist(mutable);
    return next;
  }

  Future<void> toggleCompleted({
    required String id,
    required bool value,
  }) async {
    final items = await getItems();
    final mutable =
        items
            .map(
              (item) => item.id == id ? item.copyWith(completed: value) : item,
            )
            .toList(growable: false)
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    await _persist(mutable);
  }

  Future<void> deleteItem(String id) async {
    final items = await getItems();
    final filtered = items
        .where((item) => item.id != id)
        .toList(growable: false);
    await _persist(filtered);
  }

  Future<StudyScheduleItem?> getNearestPending({DateTime? now}) async {
    final snapshot = await getItems();
    final reference = (now ?? DateTime.now()).toUtc();

    final pending =
        snapshot.where((item) => !item.completed).toList(growable: false)
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    for (final item in pending) {
      if (!item.dueAt.isBefore(reference.subtract(const Duration(days: 1)))) {
        return item;
      }
    }

    return pending.isEmpty ? null : pending.first;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _controller.add(<StudyScheduleItem>[]);
  }

  Future<void> _persist(List<StudyScheduleItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );

    await prefs.setString(_storageKey, raw);
    _controller.add(items);
  }
}
