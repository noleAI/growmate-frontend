import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local SharedPreferences store for a pending (in-progress) quiz session.
///
/// Saves enough info to allow the user to resume: topicId, questionIndex,
/// answers so far, and timestamp.
class SessionRecoveryLocal {
  static const _key = 'pending_session';

  /// Save a pending session. [data] should be JSON-serialisable.
  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
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

  /// Delete the pending session (call after completing or abandoning).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns true if there is a pending session saved.
  static Future<bool> hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}
