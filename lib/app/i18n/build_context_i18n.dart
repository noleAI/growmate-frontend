import 'package:flutter/material.dart';

import '../../shared/utils/backend_text.dart';
import 'app_strings.dart';

extension BuildContextI18n on BuildContext {
  String t({required String vi, required String en}) {
    final strings = AppStrings.of(this);
    return strings.pick(vi: repairAndCollapseText(vi), en: en);
  }

  bool get isEnglish {
    return AppStrings.of(this).isEnglish;
  }
}
