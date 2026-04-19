import 'dart:convert';

const Map<int, int> _cp1252UnicodeToByte = <int, int>{
  0x20AC: 0x80,
  0x201A: 0x82,
  0x0192: 0x83,
  0x201E: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02C6: 0x88,
  0x2030: 0x89,
  0x0160: 0x8A,
  0x2039: 0x8B,
  0x0152: 0x8C,
  0x017D: 0x8E,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201C: 0x93,
  0x201D: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x02DC: 0x98,
  0x2122: 0x99,
  0x0161: 0x9A,
  0x203A: 0x9B,
  0x0153: 0x9C,
  0x017E: 0x9E,
  0x0178: 0x9F,
};

const List<String> _suspiciousMojibakeFragments = <String>[
  'Ã',
  'Â',
  'Ä',
  'Æ',
  'áº',
  'á»',
  'â€',
  'Ä‘',
  'Æ°',
];

final RegExp _vietnameseCharPattern = RegExp(
  r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
);

String repairBackendText(String input) {
  if (input.isEmpty || !_looksSuspicious(input)) {
    return input;
  }

  var current = input;
  for (var i = 0; i < 2; i += 1) {
    final repaired = _decodeUtf8FromCp1252Mojibake(current);
    if (repaired == null || repaired == current) {
      break;
    }
    if (_readabilityScore(repaired) <= _readabilityScore(current)) {
      break;
    }
    current = repaired;
  }

  return current;
}

String repairAndCollapseText(String input) {
  return repairBackendText(input).replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

bool containsVietnameseChars(String value) {
  return _vietnameseCharPattern.hasMatch(value);
}

String? _decodeUtf8FromCp1252Mojibake(String input) {
  final bytes = <int>[];
  for (final rune in input.runes) {
    if (rune <= 0xFF) {
      bytes.add(rune);
      continue;
    }

    final mappedByte = _cp1252UnicodeToByte[rune];
    if (mappedByte == null) {
      return null;
    }
    bytes.add(mappedByte);
  }

  try {
    return utf8.decode(bytes, allowMalformed: true);
  } catch (_) {
    return null;
  }
}

bool _looksSuspicious(String value) {
  for (final fragment in _suspiciousMojibakeFragments) {
    if (value.contains(fragment)) {
      return true;
    }
  }

  for (final rune in value.runes) {
    if ((rune >= 0x80 && rune <= 0x9F) || rune == 0xFFFD) {
      return true;
    }
  }

  return false;
}

int _readabilityScore(String value) {
  final vietnameseCount = _vietnameseCharPattern.allMatches(value).length;
  final whitespaceCount = RegExp(r'\s').allMatches(value).length;
  final suspiciousCount = _countSuspiciousUnits(value);
  return (vietnameseCount * 6) + whitespaceCount - (suspiciousCount * 5);
}

int _countSuspiciousUnits(String value) {
  var count = 0;

  for (final fragment in _suspiciousMojibakeFragments) {
    count += fragment.allMatches(value).length;
  }

  for (final rune in value.runes) {
    if ((rune >= 0x80 && rune <= 0x9F) ||
        rune == 0xFFFD ||
        _cp1252UnicodeToByte.containsKey(rune)) {
      count += 1;
    }
  }

  return count;
}
