import 'package:flutter/material.dart';

import 'quiz_math_text.dart';

/// Widget hiển thị nội dung câu hỏi quiz, tự động render LaTeX.
///
/// Nếu content chứa công thức toán (dạng LaTeX inline `$...$` hoặc text có lim, phân số, v.v.),
/// sẽ render bằng [QuizMathText] (dùng flutter_math_fork).
/// Ngược lại hiển thị Text bình thường.
class QuizQuestionContent extends StatelessWidget {
  const QuizQuestionContent({
    super.key,
    required this.content,
    this.style,
    this.textAlign,
  });

  final String content;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    // Use QuizMathText which auto-detects math expressions and renders them
    // beautifully with flutter_math_fork
    return QuizMathText(
      text: content,
      style:
          style ??
          Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.3,
          ),
      textAlign: textAlign ?? TextAlign.center,
    );
  }
}
