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
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool renderAsLatex;

  @override
  Widget build(BuildContext context) {
    final normalizedText = _expandMixedTokenBoundaries(
      _normalizeDisplaySource(text),
    ).trim();
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

    // Raw backend expressions like "\lim", "\frac", "\sqrt" should
    // be treated as a full LaTeX block first; parse failures will gracefully
    // fall back to plain text via onErrorFallback.
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
    final normalizedSource = _expandMixedTokenBoundaries(source);
    final pieces = RegExp(r'\s+|\S+')
        .allMatches(normalizedSource)
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

    // LaTeX brace patterns: ^{...}, _{...}, \cmd{...}
    if (RegExp(r'[\^_]\{|\\[A-Za-z]+\{').hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(
      r'[0-9Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°Ã‚Â¹Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°Ã¢ÂÂºÃ¢ÂÂ»Ã¢ÂÂ¼Ã¢ÂÂ½Ã¢ÂÂ¾Ã‹Â£ÃŠÂ¸Ã¡Âµâ€”Ã¢ÂÂ¿]',
    ).hasMatch(cleaned)) {
      return true;
    }

    if (RegExp(
      r'[=+\-Ã¢Ë†â€™*/^Ã¢Ë†Å¡Ãâ‚¬ÃŽâ€ÃŽÂ©Ãâ€°Ã¢Ë†â€˜Ã¢Ë†Â«Ã¢â€°Â¤Ã¢â€°Â¥<>Ã¢â€ â€™Ã¢â€ Â]',
    ).hasMatch(cleaned)) {
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
        RegExp(r'[A-Za-z0-9Ãâ‚¬]').hasMatch(cleaned)) {
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

  static bool _shouldRenderWholeExpressionAsLatex(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (containsVietnameseChars(normalized) ||
        _containsProsePhrase(normalized)) {
      return false;
    }

    // Strong signal: raw LaTeX brace constructs like ^{...}, _{...}, \frac{}{}
    // These are unambiguous LaTeX and should always trigger whole-expression mode.
    final hasLatexBraces = RegExp(
      r'[\^_]\{[^}]*\}|\\[A-Za-z]+\{',
    ).hasMatch(normalized);

    // Extended LaTeX command check: include trigonometric, logarithmic, and other
    // commonly used math commands in addition to structural commands
    final hasRawCoreLatex = RegExp(
      r'\\(lim|frac|sqrt|sin|cos|tan|cot|sec|csc|ln|log|exp|pi|alpha|beta|gamma|delta|epsilon|theta|lambda|mu|nu|xi|rho|sigma|tau|phi|chi|psi|omega|partial|nabla|int|sum|prod|infty|approx|equiv|neq|leq|geq|leftarrow|rightarrow|leftrightarrow|to|prime|text|mathrm|mathbb|mathbf|cdot|times)\b',
    ).hasMatch(normalized);

    if (!hasRawCoreLatex && !hasLatexBraces) {
      return false;
    }

    // Whole-expression mode is reserved for strings that are mostly a math
    // expression, not a long prose sentence containing a small math fragment.
    // Allow formulas that contain braces like e^{\sin x}
    final startsAsExpression = RegExp(
      r'^\s*[\\\(\[\{eE0-9a-zA-Z]',
    ).hasMatch(normalized);
    final hasSentenceLikeTail = RegExp(
      r'[.!?]\s+[A-Za-z]',
    ).hasMatch(normalized);

    return startsAsExpression && !hasSentenceLikeTail;
  }

  static bool _containsProsePhrase(String source) {
    final tokens = source
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    final proseTokens = tokens
        .where(
          (token) =>
              !_isLikelyMathToken(token) && RegExp(r'[A-Za-z]').hasMatch(token),
        )
        .length;

    return proseTokens >= 2;
  }

  static MapEntry<String, String> _splitMathTrailingPunctuation(String input) {
    final match = RegExp(r'^(.*?)([,.!?;:]+)$').firstMatch(input.trimRight());
    if (match == null) {
      return MapEntry<String, String>(input, '');
    }

    return MapEntry<String, String>(match.group(1) ?? '', match.group(2) ?? '');
  }

  static String _normalizePlainMathText(String input) {
    var output = repairAndCollapseText(input)
        .replaceAll(RegExp(r'\bsqrt\s*\('), 'Ã¢Ë†Å¡(')
        .replaceAll('<=', 'Ã¢â€°Â¤')
        .replaceAll('>=', 'Ã¢â€°Â¥')
        .replaceAll('*', 'Ã‚Â·');

    output = _normalizeUnicodeSubscriptNotation(output);

    output = output.replaceAllMapped(RegExp(r'\bx[oO]\b'), (_) => 'xÃ¢â€šâ‚¬');

    output = output.replaceAllMapped(
      RegExp(
        r'lim\s*([A-Za-z])\s*(?:->|Ã¢â€ â€™)\s*([\-+]?(?:\d+(?:\.\d+)?|[Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°]+|[A-Za-z]))',
        caseSensitive: false,
      ),
      (match) =>
          'lim${match.group(1)?.toLowerCase() ?? 'x'}Ã¢â€ â€™${_normalizeLimitTarget(match.group(2) ?? '')}',
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
    var output = repairAndCollapseText(input)
        .replaceAll('Ã¢Ë†â€™', '-')
        .replaceAll('Ã¢â€°Â¤', r'\leq ')
        .replaceAll('Ã¢â€°Â¥', r'\geq ')
        .replaceAll('<=', r'\leq ')
        .replaceAll('>=', r'\geq ')
        .replaceAll('Ãƒâ€”', r'\times ')
        .replaceAll('Ã‚Â·', r'\cdot ')
        .replaceAll('*', r' \cdot ')
        .replaceAll('Ãâ‚¬', r'\pi ');

    // Normalize escaped command prefixes from serialized sources: "\\sin" -> "\sin".
    output = output.replaceAllMapped(
      RegExp(r'\\\\([A-Za-z]+)'),
      (match) => '\\${match.group(1)}',
    );

    output = _normalizeCompactFunctionCommands(output);

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
    output = output.replaceAll('Ã¢â€ â€™', r'\to ').replaceAll('->', r'\to ');
    output = _convertImplicitSubscriptsToLatex(output);

    output = _convertFunctionCallFractionsToLatex(output);
    output = _convertParenthesizedFractionsToLatex(output);
    output = _convertBracketFractionsToLatex(output);
    output = _convertSymbolicNumericFractionsToLatex(output);
    output = _convertNumericFractionsToLatex(output);

    return _convertSqrtToLatex(output);
  }

  static String _normalizeCompactFunctionCommands(String input) {
    var output = input;

    // Common malformed input from content sources: \sinx, \cos2x, \lnx, \expx.
    // Convert to canonical function-call style for flutter_math parser.
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
      output = output.replaceAllMapped(
        RegExp(
          '\\\\$command([A-Za-z0-9Ãâ‚¬](?:_[{]?[A-Za-z0-9]+[}]?)?(?:\\^{[^}]+}|\\^[A-Za-z0-9+-]+)?)',
        ),
        (match) => '\\$command ${match.group(1)}',
      );
    }

    return output;
  }

  static String _normalizeSubscriptSequences(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'([A-Za-z])([Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°]+)',
      ),
      (match) {
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
      },
    );
  }

  static String _normalizeSuperscriptSequences(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'([A-Za-z0-9Ãâ‚¬\)\}])([Ã‚Â¹Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°Ã¢ÂÂºÃ¢ÂÂ»Ã¢ÂÂ¼Ã¢ÂÂ½Ã¢ÂÂ¾Ã‹Â£ÃŠÂ¸Ã¡Âµâ€”Ã¢ÂÂ¿Ã¡ÂµÆ’Ã¡Âµâ€¡Ã¡Â¶Å“Ã¡ÂµË†Ã¡Âµâ€°Ã¡Â¶Â Ã¡ÂµÂÃŠÂ°Ã¢ÂÂ±ÃŠÂ²Ã¡ÂµÂÃ‹Â¡Ã¡ÂµÂÃ¡Âµâ€™Ã¡Âµâ€“ÃŠÂ³Ã‹Â¢Ã¡ÂµËœÃ¡Âµâ€ºÃŠÂ·Ã¡Â¶Â»]+)',
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
      RegExp(r'([A-Za-zÃâ‚¬])(\d+)'),
      (match) => '${match.group(1)}^{${match.group(2)}}',
    );
  }

  static String _convertLimitNotationToLatex(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'lim\s*(?:\(\s*)?([A-Za-z])\s*(?:->|Ã¢â€ â€™|\\to)\s*([\-+]?(?:\d+(?:\.\d+)?|[Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°]+|[A-Za-z](?:_\{?\d+\}?|\d+)?))(?:\s*\))?',
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
        .replaceAll('Ã¢â€šÂ', '(')
        .replaceAll('Ã¢â€šÅ½', ')')
        .replaceAll('Ã¢â€šâ€œ', 'x')
        .replaceAll('Ã¢â€šÅ“', 't')
        .replaceAll('Ã¢â€šâ„¢', 'n')
        .replaceAll('Ã¢â€šËœ', 'm')
        .replaceAll('Ã¢â€šâ€“', 'k')
        .replaceAll('Ã¢â€šÅ¡', 'p');

    return output;
  }

  static String _normalizeDisplaySource(String input) {
    var output = repairAndCollapseText(input);

    output = output
        .replaceAllMapped(
          RegExp(r'([)\]}])(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])(?=\\[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([.!?;,])(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([0-9])(?=[A-Za-z]{2,})'),
          (match) => '${match.group(1)} ',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ');

    return output.trim();
  }

  static String _expandMixedTokenBoundaries(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'(\\[A-Za-z]+(?:\{[^}]*\})*(?:\([^)]*\))?)(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([)\]}])(?=[A-Za-z])'),
          (match) => '${match.group(1)} ',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z]{2,})([A-Za-z])(?=\\s*[=([{\\])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([0-9}\]])(?=[A-Za-z]{2,})'),
          (match) => '${match.group(1)} ',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  static String _normalizeLimitTarget(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final normalizedDigits = trimmed.replaceAllMapped(
      RegExp(
        r'[Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°]',
      ),
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
        r'(?<!\\)(\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|-?(?:\d+(?:\.\d+)?|[A-Za-zÃâ‚¬])(?:\^\{[^}]+\}|\^[-+]?\d+|[Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°])?)\s*/\s*((?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|(?:\d+(?:\.\d+)?|[A-Za-zÃâ‚¬]))(?:\^\{[^}]+\}|\^[-+]?\d+|[Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°])?)',
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
        r'(?<!\\)(\\[A-Za-z]+|[A-Za-zÃâ‚¬](?:_\{?\d+\}?|\^\{[^}]+\}|\^[-+]?\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)(?![A-Za-z0-9])',
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
    '0': 'Ã¢ÂÂ°',
    '1': 'Ã‚Â¹',
    '2': 'Ã‚Â²',
    '3': 'Ã‚Â³',
    '4': 'Ã¢ÂÂ´',
    '5': 'Ã¢ÂÂµ',
    '6': 'Ã¢ÂÂ¶',
    '7': 'Ã¢ÂÂ·',
    '8': 'Ã¢ÂÂ¸',
    '9': 'Ã¢ÂÂ¹',
    '+': 'Ã¢ÂÂº',
    '-': 'Ã¢ÂÂ»',
    '(': 'Ã¢ÂÂ½',
    ')': 'Ã¢ÂÂ¾',
  };

  static const Map<String, String> _subscriptMap = {
    '0': 'Ã¢â€šâ‚¬',
    '1': 'Ã¢â€šÂ',
    '2': 'Ã¢â€šâ€š',
    '3': 'Ã¢â€šÆ’',
    '4': 'Ã¢â€šâ€ž',
    '5': 'Ã¢â€šâ€¦',
    '6': 'Ã¢â€šâ€ ',
    '7': 'Ã¢â€šâ€¡',
    '8': 'Ã¢â€šË†',
    '9': 'Ã¢â€šâ€°',
  };

  static const Map<String, String> _subscriptToPlainMap = {
    'Ã¢â€šâ‚¬': '0',
    'Ã¢â€šÂ': '1',
    'Ã¢â€šâ€š': '2',
    'Ã¢â€šÆ’': '3',
    'Ã¢â€šâ€ž': '4',
    'Ã¢â€šâ€¦': '5',
    'Ã¢â€šâ€ ': '6',
    'Ã¢â€šâ€¡': '7',
    'Ã¢â€šË†': '8',
    'Ã¢â€šâ€°': '9',
  };

  static const Map<String, String> _superscriptToPlainMap = {
    'Ã‚Â¹': '1',
    'Ã‚Â²': '2',
    'Ã‚Â³': '3',
    'Ã¢ÂÂ´': '4',
    'Ã¢ÂÂµ': '5',
    'Ã¢ÂÂ¶': '6',
    'Ã¢ÂÂ·': '7',
    'Ã¢ÂÂ¸': '8',
    'Ã¢ÂÂ¹': '9',
    'Ã¢ÂÂ°': '0',
    'Ã¢ÂÂº': '+',
    'Ã¢ÂÂ»': '-',
    'Ã¢ÂÂ¼': '=',
    'Ã¢ÂÂ½': '(',
    'Ã¢ÂÂ¾': ')',
    'Ã‹Â£': 'x',
    'ÃŠÂ¸': 'y',
    'Ã¡Âµâ€”': 't',
    'Ã¢ÂÂ¿': 'n',
    'Ã¡ÂµÆ’': 'a',
    'Ã¡Âµâ€¡': 'b',
    'Ã¡Â¶Å“': 'c',
    'Ã¡ÂµË†': 'd',
    'Ã¡Âµâ€°': 'e',
    'Ã¡Â¶Â ': 'f',
    'Ã¡ÂµÂ': 'g',
    'ÃŠÂ°': 'h',
    'Ã¢ÂÂ±': 'i',
    'ÃŠÂ²': 'j',
    'Ã¡ÂµÂ': 'k',
    'Ã‹Â¡': 'l',
    'Ã¡ÂµÂ': 'm',
    'Ã¡Âµâ€™': 'o',
    'Ã¡Âµâ€“': 'p',
    'ÃŠÂ³': 'r',
    'Ã‹Â¢': 's',
    'Ã¡ÂµËœ': 'u',
    'Ã¡Âµâ€º': 'v',
    'ÃŠÂ·': 'w',
    'Ã¡Â¶Â»': 'z',
  };

  static const String _legacyMathTokenPatternSource =
      r"(?<![A-Za-zÃƒâ‚¬-Ã¡Â»Â¹])(?:"
      r"lim(?:\s*[A-Za-z]|[Ã¢â€šâ€œÃ¢â€šÅ“Ã¢â€šâ„¢Ã¢â€šËœÃ¢â€šâ€“Ã¢â€šÅ¡])\s*(?:->|Ã¢â€ â€™)\s*(?:[Ã¢â€šâ‚¬Ã¢â€šÂÃ¢â€šâ€šÃ¢â€šÆ’Ã¢â€šâ€žÃ¢â€šâ€¦Ã¢â€šâ€ Ã¢â€šâ€¡Ã¢â€šË†Ã¢â€šâ€°]+|[-+]?(?:\d+(?:\.\d+)?|[A-Za-z]))|"
      r"sqrt\([^()]+\)|"
      r"(?:sin|cos|tan|ln|log)\([^)]*\)|"
      r"(?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|-?(?:\d+(?:\.\d+)?|[A-Za-zÃâ‚¬]))\s*/\s*(?:\[(?:[^\[\]]|\[[^\[\]]*\])+\]|\((?:[^()]|\([^()]*\))+\)|(?:\d+(?:\.\d+)?|[A-Za-zÃâ‚¬]))(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[Ã‚Â¹Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°Ã¢ÂÂºÃ¢ÂÂ»Ã¢ÂÂ¼Ã¢ÂÂ½Ã¢ÂÂ¾Ã‹Â£ÃŠÂ¸Ã¡Âµâ€”Ã¢ÂÂ¿Ã¡ÂµÆ’Ã¡Âµâ€¡Ã¡Â¶Å“Ã¡ÂµË†Ã¡Âµâ€°Ã¡Â¶Â Ã¡ÂµÂÃŠÂ°Ã¢ÂÂ±ÃŠÂ²Ã¡ÂµÂÃ‹Â¡Ã¡ÂµÂÃ¡Âµâ€™Ã¡Âµâ€“ÃŠÂ³Ã‹Â¢Ã¡ÂµËœÃ¡Âµâ€ºÃŠÂ·Ã¡Â¶Â»])?|"
      r"\d+/\d+(?:[A-Za-zÃâ‚¬](?:\([^)]+\))?(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[Ã‚Â¹Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°Ã¢ÂÂºÃ¢ÂÂ»Ã¢ÂÂ¼Ã¢ÂÂ½Ã¢ÂÂ¾Ã‹Â£ÃŠÂ¸Ã¡Âµâ€”Ã¢ÂÂ¿Ã¡ÂµÆ’Ã¡Âµâ€¡Ã¡Â¶Å“Ã¡ÂµË†Ã¡Âµâ€°Ã¡Â¶Â Ã¡ÂµÂÃŠÂ°Ã¢ÂÂ±ÃŠÂ²Ã¡ÂµÂÃ‹Â¡Ã¡ÂµÂÃ¡Âµâ€™Ã¡Âµâ€“ÃŠÂ³Ã‹Â¢Ã¡ÂµËœÃ¡Âµâ€ºÃŠÂ·Ã¡Â¶Â»])?)?|"
      r"(?:\d+(?:\.\d+)?)?[A-Za-zÃâ‚¬](?:\([^)]+\))?(?:\^\{[^}]+\}|\^\((?:[^()]+|\([^()]*\))*\)|\^[-+]?\d+|[Ã‚Â¹Ã‚Â²Ã‚Â³Ã¢ÂÂ´Ã¢ÂÂµÃ¢ÂÂ¶Ã¢ÂÂ·Ã¢ÂÂ¸Ã¢ÂÂ¹Ã¢ÂÂ°Ã¢ÂÂºÃ¢ÂÂ»Ã¢ÂÂ¼Ã¢ÂÂ½Ã¢ÂÂ¾Ã‹Â£ÃŠÂ¸Ã¡Âµâ€”Ã¢ÂÂ¿Ã¡ÂµÆ’Ã¡Âµâ€¡Ã¡Â¶Å“Ã¡ÂµË†Ã¡Âµâ€°Ã¡Â¶Â Ã¡ÂµÂÃŠÂ°Ã¢ÂÂ±ÃŠÂ²Ã¡ÂµÂÃ‹Â¡Ã¡ÂµÂÃ¡Âµâ€™Ã¡Âµâ€“ÃŠÂ³Ã‹Â¢Ã¡ÂµËœÃ¡Âµâ€ºÃŠÂ·Ã¡Â¶Â»])+'?|"
      r"[A-Za-z]\([^)]+\)'?|"
      r"\d+/\d+"
      r")(?![A-Za-zÃƒâ‚¬-Ã¡Â»Â¹])";

  static final RegExp _legacyMathTokenPattern = RegExp(
    _legacyMathTokenPatternSource,
    caseSensitive: false,
  );
}
