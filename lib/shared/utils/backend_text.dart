import 'dart:convert';

final RegExp _suspiciousMojibakePattern = RegExp(
  r'[ÃÂÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßâ€œâ€â€™â€“â€”â€¦]',
);

final RegExp _vietnameseCharPattern = RegExp(
  r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
);

String repairBackendText(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty || !_suspiciousMojibakePattern.hasMatch(trimmed)) {
    return input;
  }

  try {
    final repaired = utf8.decode(latin1.encode(trimmed), allowMalformed: true);
    if (_readabilityScore(repaired) > _readabilityScore(trimmed)) {
      return repaired;
    }
  } catch (_) {
    // Keep the original text when re-decoding fails.
  }

  return input;
}

String repairAndCollapseText(String input) {
  return repairBackendText(input).replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

bool containsVietnameseChars(String value) {
  return _vietnameseCharPattern.hasMatch(value);
}

int _readabilityScore(String value) {
  final vietnameseCount = _vietnameseCharPattern.allMatches(value).length;
  final suspiciousCount = _suspiciousMojibakePattern.allMatches(value).length;
  final whitespaceCount = RegExp(r'\s').allMatches(value).length;
  return (vietnameseCount * 4) + whitespaceCount - (suspiciousCount * 3);
}
