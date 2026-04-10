import 'package:flutter/material.dart';

import 'app_strings.dart';

extension BuildContextI18n on BuildContext {
  String t({required String vi, required String en}) {
    return AppStrings.of(this).pick(vi: vi, en: en);
  }

  bool get isEnglish {
    return AppStrings.of(this).isEnglish;
  }
}
