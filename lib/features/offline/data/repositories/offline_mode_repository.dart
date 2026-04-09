import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/offline_state.dart';

class OfflineModeRepository {
  OfflineModeRepository._();

  static final OfflineModeRepository instance = OfflineModeRepository._();

  static const String _enabledKey = 'offline_mode_enabled_v1';
  static const String _queueKey = 'offline_signal_queue_v1';
  static const String _lastSyncKey = 'offline_signal_last_sync_v1';

  final StreamController<OfflineState> _controller =
      StreamController<OfflineState>.broadcast();

  Stream<OfflineState> watchState() async* {
    final snapshot = await getState();
    yield snapshot;
    yield* _controller.stream;
  }

  Future<OfflineState> getState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final queue = _readQueue(prefs);
    final lastSyncRaw = prefs.getString(_lastSyncKey);

    return OfflineState(
      enabled: enabled,
      queuedSignals: queue.length,
      lastSyncedAt: DateTime.tryParse(lastSyncRaw ?? '')?.toUtc(),
    );
  }

  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await _emitState();
  }

  Future<void> enqueueSignals(List<Map<String, dynamic>> signals) async {
    if (signals.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final queue = _readQueue(prefs);
    queue.addAll(signals);

    await prefs.setString(_queueKey, jsonEncode(queue));
    await _emitState();
  }

  Future<bool> flushQueuedSignals({
    required Future<Map<String, dynamic>> Function(
      List<Map<String, dynamic>> queuedSignals,
    )
    submitter,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    if (enabled) {
      return false;
    }

    final queue = _readQueue(prefs);
    if (queue.isEmpty) {
      return true;
    }

    try {
      await submitter(queue);
      await prefs.remove(_queueKey);
      await prefs.setString(
        _lastSyncKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      await _emitState();
      return true;
    } catch (_) {
      await _emitState();
      return false;
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    await _emitState();
  }

  List<Map<String, dynamic>> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: true);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _emitState() async {
    _controller.add(await getState());
  }
}
