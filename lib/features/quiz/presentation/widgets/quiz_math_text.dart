import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class QuizMathText extends StatelessWidget {
  const QuizMathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.renderAsLatex = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool renderAsLatex;

  @override
  Widget build(BuildContext context) {
    final normalizedText = text.trim();
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

    final inlineSpans = _buildInlineLatexSpans(
      source: normalizedText,
      style: effectiveStyle,
    );

    if (inlineSpans != null) {
      return _buildRichText(inlineSpans, effectiveStyle);
    }

    final heuristicSpans = _buildHeuristicMathSpans(
      source: normalizedText,
      style: effectiveStyle,
    );

    if (heuristicSpans != null) {
      return _buildRichText(heuristicSpans, effectiveStyle);
    }

    final legacySpans = _buildLegacyMathSpans(
      source: normalizedText,
      style: effectiveStyle,
    );

    if (legacySpans != null) {
      return _buildRichText(legacySpans, effectiveStyle);
    }

    return Text(
      _normalizePlainMathText(normalizedText),
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildRichText(List<InlineSpan> spans, TextStyle? style) {
    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(style: style, children: spans),
    );
  }

  Widget _buildMathWidget({
    required String originalText,
    required String latex,
    required TextStyle? style,
  }) {
    final mathWidget = Math.tex(
      latex,
      textStyle: style,
      onErrorFallback: (_) => Text(
        _normalizePlainMathText(originalText),
        style: style,
        textAlign: textAlign,
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
    final matches = RegExp(r'\$([^\$]+)\$').allMatches(source).toList();
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

    final legacySpans = _buildLegacyMathSpans(source: source, style: style);
    if (legacySpans != null) {
      target.addAll(legacySpans);
      return;
    }

    target.add(TextSpan(text: _normalizePlainMathText(source)));
  }

  List<InlineSpan>? _buildHeuristicMathSpans({
    required String source,
    required TextStyle? style,
  }) {
    final pieces = RegExp(r'\s+|\S+')
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

      final trailingSpaceMatch = RegExp(r'\s+$').firstMatch(raw);
      final trailingSpaces = trailingSpaceMatch?.group(0) ?? '';
      if (trailingSpaceMatch != null) {
        raw = raw.substring(0, trailingSpaceMatch.start);
      }

      final split = _splitMathTrailingPunctuation(raw);
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

    for (final piece in pieces) {
      if (piece.trim().isEmpty) {
        if (mathBuffer.isNotEmpty) {
          mathBuffer.write(piece);
        } else {
          textBuffer.write(piece);
        }
        continue;
      }

      if (_isLikelyMathToken(piece)) {
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

  List<InlineSpan>? _buildLegacyMathSpans({
    required String source,
    required TextStyle? style,
  }) {
    final matches = _legacyMathTokenPattern
        .allMatches(source)
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: _normalizePlainMathText(
              source.substring(cursor, match.start),
            ),
          ),
        );
      }

      final token = match.group(0)?.trim() ?? '';
      if (token.isNotEmpty) {
        spans.add(_inlineMathSpan(token, style));
      }

      cursor = match.end;
    }

    if (cursor < source.length) {
      spans.add(
        TextSpan(text: _normalizePlainMathText(source.substring(cursor))),
      );
    }

    return spans;
  }

  static bool _isLikelyMathToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final cleaned = trimmed.replaceAll(RegExp(r'^[,;:]+|[,;:]+$'), '');
    if (cleaned.isEmpty) {
      return false;
    }

    if (RegExp(r'^[\(\[]?[A-Za-z][\)\]]$').hasMatch(cleaned)) {
      return false;
    }

    if (RegExp(r'[0-9₀₁₂₃₄₅₆₇₈₉¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻⁼⁽⁾ˣʸᵗⁿ]').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r'[=+\-−*/^√πΔΩω∑∫≤≥<>→←]').hasMatch(cleaned)) {
      return true;
    }

    // Raw LaTeX commands coming directly from backend/Supabase,
    // e.g. \sin, \cos, \frac, \sqrt, \pi, \mathbb{R}.
    if (RegExp(r'^\\[A-Za-z]+(?:\{[^}]*\})*$').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r'^\\[A-Za-z]+$').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r'[()\[\]]').hasMatch(cleaned) &&
        RegExp(r'[A-Za-z0-9π]').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(
      r'^(?:lim|sin|cos|tan|ln|log)\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r"^[A-Za-z]\([^)]+\)'?$").hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(r"^[A-Za-z](?:'|_?[0-9oO]+)?$").hasMatch(cleaned)) {
      return true;
    }

    return RegExp(r'^\(?[A-Za-z]\)?$').hasMatch(cleaned);
  }

  static MapEntry<String, String> _splitMathTrailingPunctuation(String input) {
    final match = RegExp(r'^(.*?)([,.!?;:]+)$').firstMatch(input.trimRight());
    if (match == null) {
      return MapEntry<String, String>(input, '');
    }

    return MapEntry<String, String>(match.group(1) ?? '', match.group(2) ?? '');
  }

  static String _normalizePlainMathText(String input) {
    var output = input
        .replaceAll(RegExp(r'\bsqrt\s*\('), '√(')
        .replaceAll('<=', '≤')
        .replaceAll('>=', '≥')
        .replaceAll('*', '·');

    output = _normalizeUnicodeSubscriptNotation(output);

    output = output.replaceAllMapped(RegExp(r'\bx[oO]\b'), (_) => 'x₀');

    output = output.replaceAllMapped(
      RegExp(
        r'lim\s*([A-Za-z])\s*(?:->|→)\s*([\-+]?(?:\d+(?:\.\d+)?|[₀₁₂₃₄₅₆₇₈₉]+|[A-Za-z]))',
        caseSensitive: false,
      ),
      (match) =>
          'lim${match.group(1)?.toLowerCase() ?? 'x'}→${_normalizeLimitTarget(match.group(2) ?? '')}',
    );

    output = output.replaceAllMapped(RegExp(r'([A-Za-z])([0-9])\b'), (match) {
      final base = match.group(1) ?? '';
      final subscript = _subscriptMap[match.group(2)] ?? '';
      return '$base$subscript';
    });

    output = output.replaceAllMapped(RegExp(r'\^([0-9+\-()]+)'), (match) {
      final power = match.group(1) ?? '';
      final superscript = power
          .split('')
          .map((char) => _superscriptMap[char] ?? char)
          .join();
      return superscript;
    });

    return output;
  }

  static String _normalizeLatexExpression(String input) {
    var output = input
        .replaceAll('−', '-')
        .replaceAll('≤', r'\leq ')
        .replaceAll('≥', r'\geq ')
        .replaceAll('<=', r'\leq ')
        .replaceAll('>=', r'\geq ')
        .replaceAll('×', r'\times ')
        .replaceAll('·', r'\cdot ')
        .replaceAll('*', r' \cdot ')
        .replaceAll('π', r'\pi ');

    output = _normalizeUnicodeSubscriptNotation(output);

    output = _normalizeSubscriptSequences(output);
    output = _normalizeSuperscriptSequences(output);

    output = output.replaceAllMapped(
      RegExp(r'\^\(([^()]+)\)'),
      (match) => '^{${match.group(1)}}',
    );

    output = output.replaceAllMapped(
      RegExp(r'\^([0-9A-Za-z]+)'),
      (match) => '^{${match.group(1)}}',
    );

    output = _convertLimitNotationToLatex(output);
    output = output.replaceAll('→', r'\to ').replaceAll('->', r'\to ');
    output = _convertImplicitSubscriptsToLatex(output);

    output = _convertFunctionCallFractionsToLatex(output);
    output = _convertParenthesizedFractionsToLatex(output);
    output = _convertBracketFractionsToLatex(output);
    output = _convertSymbolicNumericFractionsToLatex(output);
    output = _convertNumericFractionsToLatex(output);

    return _convertSqrtToLatex(output);
  }

  static String _normalizeSubscriptSequences(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Za-z])([₀₁₂₃₄₅₆₇₈₉]+)'), (
      match,
    ) {
      final base = match.group(1) ?? '';
      final raw = match.group(2) ?? '';
      final plainDigits = raw
          .split('')
          .map((char) => _subscriptToPlainMap[char] ?? '')
          .join();

      if (plainDigits.isEmpty) {
        return match.group(0) ?? '';
      }

      return '${base}_{$plainDigits}';
    });
  }

  static String _normalizeSuperscriptSequences(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'([A-Za-z0-9π\)\}])([¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻⁼⁽⁾ˣʸᵗⁿᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐᵒᵖʳˢᵘᵛʷᶻ]+)',
      ),
      (match) {
        final base = match.group(1) ?? '';
        final superscriptRaw = match.group(2) ?? '';
        final plainExponent = superscriptRaw
            .split('')
            .map((char) => _superscriptToPlainMap[char] ?? '')
            .join();

        if (plainExponent.isEmpty) {
          return match.group(0) ?? '';
        }

        return '$base^{${_normalizeExponentFragment(plainExponent)}}';
      },
    );
  }

  static String _normalizeExponentFragment(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (RegExp(r'^[-+]?\d+(?:\.\d+)?$').hasMatch(trimmed)) {
      return trimmed;
    }

    return trimmed.replaceAllMapped(
      RegExp(r'([A-Za-zπ])(\d+)'),
      (match) => '${match.group(1)}^{${match.group(2)}}',
    );
  }

  static String _convertLimitNotationToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'lim\s*(?:\(\s*)?([A-Za-z])\s*(?:->|→|\\to)\s*([\-+]?(?:\d+(?:\.\d+)?|[₀₁₂₃₄₅₆₇₈₉]+|[A-Za-z](?:_\{?\d+\}?|\d+)?))(?:\s*\))?',
        caseSensitive: false,
      ),
      (match) {
        final variable = match.group(1)?.toLowerCase() ?? 'x';
        final target = _normalizeLimitTarget(match.group(2) ?? '');
        return '\\lim_{$variable\\to $target}';
      },
    );
  }

  static String _normalizeUnicodeSubscriptNotation(String input) {
    var output = input
        .replaceAll('₍', '(')
        .replaceAll('₎', ')')
        .replaceAll('ₓ', 'x')
        .replaceAll('ₜ', 't')
        .replaceAll('ₙ', 'n')
        .replaceAll('ₘ', 'm')
        .replaceAll('ₖ', 'k')
        .replaceAll('ₚ', 'p');

    return output;
  }

  static String _normalizeLimitTarget(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final normalizedDigits = trimmed.replaceAllMapped(
      RegExp(r'[₀₁₂₃₄₅₆₇₈₉]'),
      (match) => _subscriptToPlainMap[match.group(0)] ?? '',
    );

    return normalizedDigits.replaceAllMapped(RegExp(r'([A-Za-z])(\d+)'), (
      match,
    ) {
      return '${match.group(1)}_{${match.group(2)}}';
    });
  }

  static String _convertImplicitSubscriptsToLatex(String input) {
    var output = input.replaceAllMapped(RegExp(r'\bx[oO]\b'), (_) => 'x_{0}');
    output = output.replaceAllMapped(RegExp(r'\bx0\b'), (_) => 'x_{0}');

    output = output.replaceAllMapped(RegExp(r'([A-Za-z])([0-9])\b'), (match) {
      return '${match.group(1)}_{${match.group(2)}}';
    });

    return output;
  }

  static String _convertBracketFractionsToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'(?<!\\)(\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|-?(?:\d+(?:\.\d+)?|[A-Za-zπ])(?:\^\{[^}]+\}|\^[-+]?\d+|[²³⁴⁵⁶⁷⁸⁹⁰])?)\s*/\s*((?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|(?:\d+(?:\.\d+)?|[A-Za-zπ]))(?:\^\{[^}]+\}|\^[-+]?\d+|[²³⁴⁵⁶⁷⁸⁹⁰])?)',
      ),
      (match) => '\\frac{${match.group(1) ?? ''}}{${match.group(2) ?? ''}}',
    );
  }

  static String _convertFunctionCallFractionsToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'(?<!\\)(-?(?:\d+(?:\.\d+)?(?:\^\{[^}]+\}|\^[-+]?\d+)?|[A-Za-z](?:\^\{[^}]+\}|\^[-+]?\d+)?|\\[A-Za-z]+(?:\{[^}]+\})?))\s*/\s*((?:\\[A-Za-z]+|[A-Za-z]{2,})\([^()]+\))',
      ),
      (match) => '\\frac{${match.group(1) ?? ''}}{${match.group(2) ?? ''}}',
    );
  }

  static String _convertParenthesizedFractionsToLatex(String input) {
    var output = input;
    var cursor = 0;

    while (cursor < output.length) {
      final slashIndex = output.indexOf('/', cursor);
      if (slashIndex == -1) {
        break;
      }

      var leftEnd = slashIndex - 1;
      while (leftEnd >= 0 && output[leftEnd].trim().isEmpty) {
        leftEnd -= 1;
      }

      if (leftEnd < 0 || output[leftEnd] != ')') {
        cursor = slashIndex + 1;
        continue;
      }

      final leftStart = _findMatchingOpeningParen(output, leftEnd);
      if (leftStart == -1) {
        cursor = slashIndex + 1;
        continue;
      }

      var rightStart = slashIndex + 1;
      while (rightStart < output.length && output[rightStart].trim().isEmpty) {
        rightStart += 1;
      }

      if (rightStart >= output.length || output[rightStart] != '(') {
        cursor = slashIndex + 1;
        continue;
      }

      final rightEnd = _findMatchingClosingParen(output, rightStart);
      if (rightEnd == -1) {
        cursor = slashIndex + 1;
        continue;
      }

      final numerator = output.substring(leftStart + 1, leftEnd);
      final denominator = output.substring(rightStart + 1, rightEnd);
      final replacement = '\\frac{$numerator}{$denominator}';

      output =
          output.substring(0, leftStart) +
          replacement +
          output.substring(rightEnd + 1);
      cursor = leftStart + replacement.length;
    }

    return output;
  }

  static int _findMatchingOpeningParen(String source, int closeIndex) {
    var depth = 0;
    for (var i = closeIndex; i >= 0; i -= 1) {
      final char = source[i];
      if (char == ')') {
        depth += 1;
      } else if (char == '(') {
        depth -= 1;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  static int _findMatchingClosingParen(String source, int openIndex) {
    var depth = 0;
    for (var i = openIndex; i < source.length; i += 1) {
      final char = source[i];
      if (char == '(') {
        depth += 1;
      } else if (char == ')') {
        depth -= 1;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  static String _convertNumericFractionsToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(r'(?<![\\\w])(-?\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)'),
      (match) => '\\frac{${match.group(1) ?? ''}}{${match.group(2) ?? ''}}',
    );
  }

  static String _convertSymbolicNumericFractionsToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'(?<!\\)(\\[A-Za-z]+|[A-Za-zπ](?:_\{?\d+\}?|\^\{[^}]+\}|\^[-+]?\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)(?![A-Za-z0-9])',
      ),
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
        ? r'\displaystyle ' + normalized
        : normalized;

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Math.tex(
        displayLatex,
        textStyle: style,
        onErrorFallback: (_) =>
            Text(_normalizePlainMathText(rawLatex), style: style),
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
        final rest = input.substring(expressionStart);
        buffer
          ..write(r'\sqrt{')
          ..write(rest)
          ..write('}');
        index = input.length;
      }
    }

    return buffer.toString();
  }

  static Alignment _alignmentFromTextAlign(TextAlign value) {
    return switch (value) {
      TextAlign.center => Alignment.center,
      TextAlign.end || TextAlign.right => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }

  static const Map<String, String> _superscriptMap = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    '(': '⁽',
    ')': '⁾',
  };

  static const Map<String, String> _subscriptMap = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
  };

  static const Map<String, String> _subscriptToPlainMap = {
    '₀': '0',
    '₁': '1',
    '₂': '2',
    '₃': '3',
    '₄': '4',
    '₅': '5',
    '₆': '6',
    '₇': '7',
    '₈': '8',
    '₉': '9',
  };

  static const Map<String, String> _superscriptToPlainMap = {
    '¹': '1',
    '²': '2',
    '³': '3',
    '⁴': '4',
    '⁵': '5',
    '⁶': '6',
    '⁷': '7',
    '⁸': '8',
    '⁹': '9',
    '⁰': '0',
    '⁺': '+',
    '⁻': '-',
    '⁼': '=',
    '⁽': '(',
    '⁾': ')',
    'ˣ': 'x',
    'ʸ': 'y',
    'ᵗ': 't',
    'ⁿ': 'n',
    'ᵃ': 'a',
    'ᵇ': 'b',
    'ᶜ': 'c',
    'ᵈ': 'd',
    'ᵉ': 'e',
    'ᶠ': 'f',
    'ᵍ': 'g',
    'ʰ': 'h',
    'ⁱ': 'i',
    'ʲ': 'j',
    'ᵏ': 'k',
    'ˡ': 'l',
    'ᵐ': 'm',
    'ᵒ': 'o',
    'ᵖ': 'p',
    'ʳ': 'r',
    'ˢ': 's',
    'ᵘ': 'u',
    'ᵛ': 'v',
    'ʷ': 'w',
    'ᶻ': 'z',
  };

  static const String _legacyMathTokenPatternSource =
      r"(?<![A-Za-zÀ-ỹ])(?:"
      r"lim(?:\s*[A-Za-z]|[ₓₜₙₘₖₚ])\s*(?:->|→)\s*(?:[₀₁₂₃₄₅₆₇₈₉]+|[-+]?(?:\d+(?:\.\d+)?|[A-Za-z]))|"
      r"sqrt\([^()]+\)|"
      r"(?:sin|cos|tan|ln|log)\([^)]*\)|"
      r"(?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|-?(?:\d+(?:\.\d+)?|[A-Za-zπ]))\s*/\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|(?:\d+(?:\.\d+)?|[A-Za-zπ]))(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻⁼⁽⁾ˣʸᵗⁿᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐᵒᵖʳˢᵘᵛʷᶻ])?|"
      r"\d+/\d+(?:[A-Za-zπ](?:\([^)]+\))?(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻⁼⁽⁾ˣʸᵗⁿᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐᵒᵖʳˢᵘᵛʷᶻ])?)?|"
      r"(?:\d+(?:\.\d+)?)?[A-Za-zπ](?:\([^)]+\))?(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[¹²³⁴⁵⁶⁷⁸⁹⁰⁺⁻⁼⁽⁾ˣʸᵗⁿᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐᵒᵖʳˢᵘᵛʷᶻ])+'?|"
      r"[A-Za-z]\([^)]+\)'?|"
      r"\d+/\d+"
      r")(?![A-Za-zÀ-ỹ])";

  static final RegExp _legacyMathTokenPattern = RegExp(
    _legacyMathTokenPatternSource,
    caseSensitive: false,
  );
}
