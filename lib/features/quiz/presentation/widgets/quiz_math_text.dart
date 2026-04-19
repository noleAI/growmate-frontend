import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../shared/utils/backend_text.dart';

class QuizMathText extends StatelessWidget {
  const QuizMathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.renderAsLatex = false,
    this.preferPlainTextForMixedContent = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool renderAsLatex;
  final bool preferPlainTextForMixedContent;

  static final RegExp _inlineLatexPattern = RegExp(r'\$([^\$]+)\$');
  static final RegExp _piecePattern = RegExp(r'\s+|\S+');
  static final RegExp _commandPattern = RegExp(r'\\[A-Za-z]+');
  static final RegExp _operatorPattern = RegExp(
    r'^(?:=|<=|>=|->|[+\-*/^_<>])+$',
  );
  static final RegExp _singleLetterPattern = RegExp(r'^[A-Za-z]$');
  static final RegExp _wrappedSingleLetterPattern = RegExp(
    r'^[\(\[]?[A-Za-z][\)\]]$',
  );
  static final RegExp _functionCallPattern = RegExp(r'^[A-Za-z]+\([^)]*\)$');
  static final RegExp _simpleFractionPattern = RegExp(
    r'(?<!\\)(\([^()]+\)|\[[^\[\]]+\]|[A-Za-z0-9\\{}_^.+\-]+)\s*/\s*(\([^()]+\)|\[[^\[\]]+\]|[A-Za-z0-9\\{}_^.+\-]+)',
  );

  static const Map<String, String> _superscriptMap = <String, String>{
    '0': '\u2070',
    '1': '\u00B9',
    '2': '\u00B2',
    '3': '\u00B3',
    '4': '\u2074',
    '5': '\u2075',
    '6': '\u2076',
    '7': '\u2077',
    '8': '\u2078',
    '9': '\u2079',
    '+': '\u207A',
    '-': '\u207B',
    '(': '\u207D',
    ')': '\u207E',
  };

  static const Map<String, String> _subscriptMap = <String, String>{
    '0': '\u2080',
    '1': '\u2081',
    '2': '\u2082',
    '3': '\u2083',
    '4': '\u2084',
    '5': '\u2085',
    '6': '\u2086',
    '7': '\u2087',
    '8': '\u2088',
    '9': '\u2089',
  };

  static final Map<String, String> _subscriptToPlainMap = <String, String>{
    for (final entry in _subscriptMap.entries) entry.value: entry.key,
  };

  static final Map<String, String> _superscriptToPlainMap = <String, String>{
    for (final entry in _superscriptMap.entries) entry.value: entry.key,
  };

  @override
  Widget build(BuildContext context) {
    final normalizedText = _normalizeDisplaySource(text).trim();
    if (normalizedText.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    if (renderAsLatex) {
      return _buildMathWidget(
        originalText: normalizedText,
        latex: _normalizeLatexExpression(normalizedText),
        style: effectiveStyle,
      );
    }

    if (_shouldRenderWholeExpressionAsLatex(normalizedText)) {
      return _buildMathWidget(
        originalText: normalizedText,
        latex: _normalizeLatexExpression(normalizedText),
        style: effectiveStyle,
      );
    }

    final inlineSpans = _buildInlineLatexSpans(
      source: normalizedText,
      style: effectiveStyle,
    );
    if (inlineSpans != null) {
      return _buildRichText(inlineSpans, effectiveStyle);
    }

    if (preferPlainTextForMixedContent &&
        _containsProsePhrase(normalizedText)) {
      return Text(
        _normalizePlainMathText(normalizedText),
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final heuristicSpans = _buildHeuristicMathSpans(
      source: normalizedText,
      style: effectiveStyle,
    );
    if (heuristicSpans != null) {
      return _buildRichText(heuristicSpans, effectiveStyle);
    }

    return Text(
      _normalizePlainMathText(normalizedText),
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildRichText(List<InlineSpan> spans, TextStyle? textStyle) {
    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(style: textStyle, children: spans),
    );
  }

  Widget _buildMathWidget({
    required String originalText,
    required String latex,
    required TextStyle? style,
  }) {
    final displayLatex = _shouldUseDisplayStyle(latex)
        ? '\\displaystyle $latex'
        : latex;

    final mathWidget = Math.tex(
      displayLatex,
      textStyle: style,
      onErrorFallback: (_) => Text(
        _normalizePlainMathText(originalText),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );

    return Align(
      alignment: _alignmentFromTextAlign(textAlign),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: mathWidget,
      ),
    );
  }

  List<InlineSpan>? _buildInlineLatexSpans({
    required String source,
    required TextStyle? style,
  }) {
    final matches = _inlineLatexPattern
        .allMatches(source)
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        _appendMathOrTextSpans(
          source: source.substring(cursor, match.start),
          style: style,
          target: spans,
        );
      }

      final rawLatex = match.group(1)?.trim() ?? '';
      if (rawLatex.isNotEmpty) {
        spans.add(_inlineMathSpan(rawLatex, style));
      }

      cursor = match.end;
    }

    if (cursor < source.length) {
      _appendMathOrTextSpans(
        source: source.substring(cursor),
        style: style,
        target: spans,
      );
    }

    return spans;
  }

  void _appendMathOrTextSpans({
    required String source,
    required TextStyle? style,
    required List<InlineSpan> target,
  }) {
    if (source.isEmpty) {
      return;
    }

    final heuristicSpans = _buildHeuristicMathSpans(
      source: source,
      style: style,
    );
    if (heuristicSpans != null) {
      target.addAll(heuristicSpans);
      return;
    }

    target.add(TextSpan(text: _normalizePlainMathText(source)));
  }

  List<InlineSpan>? _buildHeuristicMathSpans({
    required String source,
    required TextStyle? style,
  }) {
    final pieces = _piecePattern
        .allMatches(source)
        .map((match) => match.group(0) ?? '')
        .toList(growable: false);

    if (pieces.isEmpty) {
      return null;
    }

    final spans = <InlineSpan>[];
    final textBuffer = StringBuffer();
    final mathBuffer = StringBuffer();
    var hasMath = false;

    void flushText() {
      if (textBuffer.isEmpty) {
        return;
      }
      spans.add(TextSpan(text: _normalizePlainMathText(textBuffer.toString())));
      textBuffer.clear();
    }

    void flushMath() {
      if (mathBuffer.isEmpty) {
        return;
      }

      var raw = mathBuffer.toString();
      mathBuffer.clear();

      final trailingSpacesMatch = RegExp(r'\s+$').firstMatch(raw);
      final trailingSpaces = trailingSpacesMatch?.group(0) ?? '';
      if (trailingSpacesMatch != null) {
        raw = raw.substring(0, trailingSpacesMatch.start);
      }

      final split = _splitTrailingPunctuation(raw);
      final mathPart = split.key.trim();
      final trailingPunctuation = split.value;

      if (mathPart.isNotEmpty) {
        spans.add(_inlineMathSpan(mathPart, style));
        hasMath = true;
      }

      if (trailingPunctuation.isNotEmpty) {
        spans.add(TextSpan(text: trailingPunctuation));
      }

      if (trailingSpaces.isNotEmpty) {
        spans.add(TextSpan(text: trailingSpaces));
      }
    }

    for (var index = 0; index < pieces.length; index += 1) {
      final piece = pieces[index];
      if (piece.trim().isEmpty) {
        if (mathBuffer.isNotEmpty) {
          mathBuffer.write(piece);
        } else {
          textBuffer.write(piece);
        }
        continue;
      }

      final previous = _previousNonWhitespaceToken(pieces, index);
      final next = _nextNonWhitespaceToken(pieces, index);

      if (_isLikelyMathToken(piece, previous: previous, next: next)) {
        flushText();
        mathBuffer.write(piece);
      } else {
        flushMath();
        textBuffer.write(piece);
      }
    }

    flushMath();
    flushText();

    return hasMath ? spans : null;
  }

  String? _previousNonWhitespaceToken(List<String> pieces, int index) {
    for (var cursor = index - 1; cursor >= 0; cursor -= 1) {
      if (pieces[cursor].trim().isNotEmpty) {
        return pieces[cursor];
      }
    }
    return null;
  }

  String? _nextNonWhitespaceToken(List<String> pieces, int index) {
    for (var cursor = index + 1; cursor < pieces.length; cursor += 1) {
      if (pieces[cursor].trim().isNotEmpty) {
        return pieces[cursor];
      }
    }
    return null;
  }

  bool _isLikelyMathToken(String token, {String? previous, String? next}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final cleaned = trimmed.replaceAll(RegExp(r'^[,;:]+|[,;:]+$'), '');
    if (cleaned.isEmpty) {
      return false;
    }

    if (containsVietnameseChars(cleaned) || _looksLikePlainWord(cleaned)) {
      return false;
    }

    if (_operatorPattern.hasMatch(cleaned)) {
      return true;
    }

    if (_singleLetterPattern.hasMatch(cleaned) ||
        _wrappedSingleLetterPattern.hasMatch(cleaned)) {
      return _hasMathContext(previous) || _hasMathContext(next);
    }

    if (_commandPattern.hasMatch(cleaned) ||
        cleaned.contains(r'^{') ||
        cleaned.contains(r'_{') ||
        cleaned.contains(r'\prime')) {
      return true;
    }

    if (_functionCallPattern.hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r'\d').hasMatch(cleaned) || _containsUnicodeDigits(cleaned)) {
      return true;
    }

    if (RegExp(r'[=<>+\-*/^_]').hasMatch(cleaned) &&
        RegExp(r'[A-Za-z0-9()]').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(
      r'^(?:lim|sin|cos|tan|ln|log|exp)\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(
      r"^[A-Za-z](?:'|′|_\{?[^}\s]+\}?|\^[A-Za-z0-9+\-]+|\^\{[^}]+\})+$",
    ).hasMatch(cleaned)) {
      return true;
    }

    return false;
  }

  bool _hasMathContext(String? token) {
    if (token == null) {
      return false;
    }

    final cleaned = token.trim();
    if (cleaned.isEmpty) {
      return false;
    }

    return _operatorPattern.hasMatch(cleaned) ||
        _commandPattern.hasMatch(cleaned) ||
        cleaned.contains(r'^{') ||
        cleaned.contains(r'_{') ||
        RegExp(r'[=<>+\-*/^_]').hasMatch(cleaned) ||
        RegExp(r'\d').hasMatch(cleaned) ||
        _containsUnicodeDigits(cleaned) ||
        _functionCallPattern.hasMatch(cleaned);
  }

  static bool _looksLikePlainWord(String value) {
    if (value.length <= 1) {
      return false;
    }

    if (!RegExp(r'^[A-Za-z]+$').hasMatch(value)) {
      return false;
    }

    const reservedMathWords = <String>{
      'lim',
      'sin',
      'cos',
      'tan',
      'ln',
      'log',
      'exp',
      'sqrt',
    };

    return !reservedMathWords.contains(value.toLowerCase());
  }

  static bool _containsUnicodeDigits(String value) {
    for (final char in value.split('')) {
      if (_subscriptToPlainMap.containsKey(char) ||
          _superscriptToPlainMap.containsKey(char)) {
        return true;
      }
    }
    return false;
  }

  static bool _shouldRenderWholeExpressionAsLatex(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (_containsProsePhrase(normalized)) {
      return false;
    }

    return _commandPattern.hasMatch(normalized) ||
        normalized.contains(r'^{') ||
        normalized.contains(r'_{') ||
        RegExp(r'[=<>+\-*/^_]').hasMatch(normalized);
  }

  static bool _containsProsePhrase(String source) {
    final tokens = source
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    var proseTokens = 0;
    for (final token in tokens) {
      if (containsVietnameseChars(token) || _looksLikePlainWord(token)) {
        proseTokens += 1;
      }
      if (proseTokens >= 2) {
        return true;
      }
    }

    return false;
  }

  static MapEntry<String, String> _splitTrailingPunctuation(String input) {
    final match = RegExp(r'^(.*?)([,.!?;:]+)$').firstMatch(input.trimRight());
    if (match == null) {
      return MapEntry<String, String>(input, '');
    }

    return MapEntry<String, String>(match.group(1) ?? '', match.group(2) ?? '');
  }

  static String _normalizePlainMathText(String input) {
    var output = repairAndCollapseText(input)
        .replaceAll(RegExp(r'\bsqrt\s*\('), '\u221A(')
        .replaceAll('<=', '\u2264')
        .replaceAll('>=', '\u2265')
        .replaceAll('->', '\u2192')
        .replaceAll(r'\to', '\u2192')
        .replaceAll(r'\pi', '\u03C0')
        .replaceAll(r'\cdot', '\u00B7')
        .replaceAll(r'\times', '\u00D7')
        .replaceAll(r'\prime', "'")
        .replaceAll('*', '\u00B7');

    output = output.replaceAllMapped(
      RegExp(r'\bx0\b', caseSensitive: false),
      (_) => 'x\u2080',
    );
    output = _applyDisplaySubscripts(output);
    output = _applyDisplaySuperscripts(output);
    return output;
  }

  static String _normalizeLatexExpression(String input) {
    var output = repairAndCollapseText(input)
        .replaceAll('\u2264', r'\leq ')
        .replaceAll('\u2265', r'\geq ')
        .replaceAll('<=', r'\leq ')
        .replaceAll('>=', r'\geq ')
        .replaceAll('\u00D7', r'\times ')
        .replaceAll('\u00B7', r'\cdot ')
        .replaceAll('*', r' \cdot ')
        .replaceAll('\u03C0', r'\pi ')
        .replaceAll('\u2192', r'\to ')
        .replaceAll('->', r'\to ')
        .replaceAll('\u221A', 'sqrt');

    output = output.replaceAllMapped(
      RegExp(r'\\\\([A-Za-z]+)'),
      (match) => '\\${match.group(1)}',
    );

    output = _normalizeUnicodeDigitsToAscii(output);
    output = _normalizeCompactFunctionCommands(output);
    output = output.replaceAllMapped(
      RegExp(r'\^\(([^()]+)\)'),
      (match) => '^{${match.group(1)}}',
    );
    output = output.replaceAllMapped(
      RegExp(r'\^([0-9A-Za-z+\-]+)'),
      (match) => '^{${match.group(1)}}',
    );

    output = _convertLimitNotationToLatex(output);
    output = _convertImplicitSubscriptsToLatex(output);
    output = _convertSimpleFractionsToLatex(output);
    output = _convertSqrtToLatex(output);
    return output;
  }

  static String _normalizeCompactFunctionCommands(String input) {
    var output = input;
    const unaryCommands = <String>[
      'sin',
      'cos',
      'tan',
      'cot',
      'sec',
      'csc',
      'ln',
      'log',
      'exp',
    ];

    for (final command in unaryCommands) {
      final token = '\\$command';
      var searchStart = 0;

      while (searchStart < output.length) {
        final tokenIndex = output.indexOf(token, searchStart);
        if (tokenIndex == -1) {
          break;
        }

        final suffixIndex = tokenIndex + token.length;
        if (suffixIndex >= output.length) {
          break;
        }

        final nextChar = output[suffixIndex];
        final shouldInsertSpace =
            !RegExp(r'[\s{(]').hasMatch(nextChar) &&
            RegExp(r'[A-Za-z0-9]').hasMatch(nextChar);

        if (shouldInsertSpace) {
          output =
              '${output.substring(0, suffixIndex)} ${output.substring(suffixIndex)}';
          searchStart = suffixIndex + 2;
        } else {
          searchStart = suffixIndex + 1;
        }
      }
    }

    return output;
  }

  static String _normalizeUnicodeDigitsToAscii(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(
        _subscriptToPlainMap[char] ?? _superscriptToPlainMap[char] ?? char,
      );
    }
    return buffer.toString();
  }

  static String _applyDisplaySubscripts(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Za-z])_\{?(\d+)\}?'), (match) {
      final digits = match.group(2) ?? '';
      final rendered = digits
          .split('')
          .map((char) => _subscriptMap[char] ?? char)
          .join();
      return '${match.group(1)}$rendered';
    });
  }

  static String _applyDisplaySuperscripts(String input) {
    return input.replaceAllMapped(RegExp(r'\^\{?([0-9+\-()]+)\}?'), (match) {
      final exponent = match.group(1) ?? '';
      return exponent
          .split('')
          .map((char) => _superscriptMap[char] ?? char)
          .join();
    });
  }

  static String _convertLimitNotationToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'lim\s*([A-Za-z])\s*(?:->|\\to)\s*([\-+]?\d+(?:\.\d+)?|[A-Za-z])',
        caseSensitive: false,
      ),
      (match) {
        final variable = (match.group(1) ?? 'x').toLowerCase();
        final target = match.group(2) ?? '';
        return '\\lim_{$variable\\to $target}';
      },
    );
  }

  static String _convertImplicitSubscriptsToLatex(String input) {
    var output = input.replaceAllMapped(
      RegExp(r'\bx0\b', caseSensitive: false),
      (_) => 'x_{0}',
    );

    output = output.replaceAllMapped(
      RegExp(r'([A-Za-z])(\d+)\b'),
      (match) => '${match.group(1)}_{${match.group(2)}}',
    );

    return output;
  }

  static String _convertSimpleFractionsToLatex(String input) {
    return input.replaceAllMapped(
      _simpleFractionPattern,
      (match) => '\\frac{${match.group(1) ?? ''}}{${match.group(2) ?? ''}}',
    );
  }

  static bool _shouldUseDisplayStyle(String normalizedLatex) {
    return normalizedLatex.contains(r'\frac') ||
        normalizedLatex.contains(r'\lim') ||
        normalizedLatex.contains(r'\sum') ||
        normalizedLatex.contains(r'\int');
  }

  InlineSpan _inlineMathSpan(String rawLatex, TextStyle? style) {
    final normalized = _normalizeLatexExpression(rawLatex);
    final displayLatex = _shouldUseDisplayStyle(normalized)
        ? '\\displaystyle $normalized'
        : normalized;

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: Math.tex(
          displayLatex,
          textStyle: style,
          onErrorFallback: (_) =>
              Text(_normalizePlainMathText(rawLatex), style: style),
        ),
      ),
    );
  }

  static String _convertSqrtToLatex(String input) {
    final buffer = StringBuffer();
    var index = 0;

    while (index < input.length) {
      final sqrtIndex = input.indexOf('sqrt(', index);
      if (sqrtIndex == -1) {
        buffer.write(input.substring(index));
        break;
      }

      buffer.write(input.substring(index, sqrtIndex));

      final expressionStart = sqrtIndex + 5;
      var depth = 1;
      var cursor = expressionStart;

      while (cursor < input.length && depth > 0) {
        final char = input[cursor];
        if (char == '(') {
          depth += 1;
        } else if (char == ')') {
          depth -= 1;
        }
        cursor += 1;
      }

      if (depth == 0) {
        final inner = input.substring(expressionStart, cursor - 1);
        buffer
          ..write(r'\sqrt{')
          ..write(_convertSqrtToLatex(inner))
          ..write('}');
        index = cursor;
      } else {
        buffer
          ..write(r'\sqrt{')
          ..write(input.substring(expressionStart))
          ..write('}');
        index = input.length;
      }
    }

    return buffer.toString();
  }

  static String _normalizeDisplaySource(String input) {
    return repairAndCollapseText(input)
        .replaceAllMapped(
          RegExp(r'([)\]}])(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([.!?;,])(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])(?=\\[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static Alignment _alignmentFromTextAlign(TextAlign value) {
    return switch (value) {
      TextAlign.center => Alignment.center,
      TextAlign.end || TextAlign.right => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }
}
