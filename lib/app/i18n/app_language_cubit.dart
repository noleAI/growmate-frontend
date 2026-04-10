import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { vietnamese, english }

extension AppLanguageX on AppLanguage {
  String get storageValue {
    switch (this) {
      case AppLanguage.vietnamese:
        return 'vi';
      case AppLanguage.english:
        return 'en';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.vietnamese:
        return const Locale('vi');
      case AppLanguage.english:
        return const Locale('en');
    }
  }
}

class AppLanguageCubit extends Cubit<AppLanguage> {
  AppLanguageCubit() : super(AppLanguage.vietnamese);

  static const String _prefsKey = 'app_language';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) {
      return;
    }

    emit(_deserialize(saved));
  }

  Future<void> setLanguage(AppLanguage language) async {
    emit(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.storageValue);
  }

  static AppLanguage _deserialize(String value) {
    switch (value) {
      case 'en':
        return AppLanguage.english;
      case 'vi':
      default:
        return AppLanguage.vietnamese;
    }
  }
}
