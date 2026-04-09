import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit() : super(ThemeMode.light);

  static const String _prefsKey = 'theme_mode';

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) {
      return;
    }

    emit(_deserialize(saved));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _serialize(mode));
  }

  Future<void> setDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _deserialize(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
