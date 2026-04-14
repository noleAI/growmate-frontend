import 'package:shared_preferences/shared_preferences.dart';

/// Chế độ học của user: Luyện thi (exam-focused) hoặc Trải nghiệm (casual).
enum StudyMode {
  examPrep, // 🎓 Luyện thi — timer, scoring, limited hints
  casual; // 🎮 Trải nghiệm — no timer, unlimited hints

  String get storageValue => switch (this) {
    StudyMode.examPrep => 'exam_prep',
    StudyMode.casual => 'casual',
  };

  static StudyMode fromStorageValue(String? raw) {
    return switch (raw) {
      'casual' => StudyMode.casual,
      _ => StudyMode.examPrep,
    };
  }
}

/// Persistent storage for study mode preference.
class StudyModeRepository {
  StudyModeRepository._();
  static final StudyModeRepository instance = StudyModeRepository._();

  static const String _key = 'study_mode';

  Future<StudyMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyMode.fromStorageValue(prefs.getString(_key));
  }

  Future<void> setMode(StudyMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.storageValue);
  }
}
