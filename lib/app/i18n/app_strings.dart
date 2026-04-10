import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings._({required bool isEnglish}) : _isEnglish = isEnglish;

  final bool _isEnglish;

  static AppStrings of(BuildContext context) {
    final isEnglish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('en');
    return AppStrings._(isEnglish: isEnglish);
  }

  bool get isEnglish => _isEnglish;

  String pick({required String vi, required String en}) {
    return _isEnglish ? en : vi;
  }

  String get tabHome => pick(vi: 'Trang chủ', en: 'Home');
  String get tabProgress => pick(vi: 'Tiến trình', en: 'Progress');
  String get tabRoadmap => pick(vi: 'Roadmap', en: 'Roadmap');
  String get tabProfile => pick(vi: 'Hồ sơ', en: 'Profile');
  String get tabSettings => pick(vi: 'Cài đặt', en: 'Settings');

  String get languageVietnamese => pick(vi: 'Tiếng Việt', en: 'Vietnamese');
  String get languageEnglish => 'English';
}
