import 'package:flutter/foundation.dart';

class MoodStateService {
  MoodStateService._internal();

  static final MoodStateService _instance = MoodStateService._internal();

  static MoodStateService get instance => _instance;

  final ValueNotifier<String> moodState = ValueNotifier<String>('Focused');

  void setMood(String value) {
    moodState.value = value;
  }
}
