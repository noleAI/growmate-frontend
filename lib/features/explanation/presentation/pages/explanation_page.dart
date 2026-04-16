import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';
import '../../../quiz/presentation/widgets/quiz_math_text.dart';

/// Page for detailed step-by-step explanation of a quiz question.
///
/// Supports LaTeX rendering and (future) MANIM video playback.
class ExplanationPage extends StatelessWidget {
  const ExplanationPage({
    super.key,
    required this.questionContent,
    required this.explanation,
    this.formula,
    this.manimVideoUrl,
  });

  final String questionContent;
  final String explanation;
  final String? formula;
  final String? manimVideoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t(vi: 'Giải thích', en: 'Explanation'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GrowMateLayout.sectionGap),
        children: [
          // Question
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(vi: '📝 Câu hỏi', en: '📝 Question'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                QuizMathText(
                  text: questionContent,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: GrowMateLayout.sectionGap),

          // Formula (if any)
          if (formula != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(vi: '📐 Công thức', en: '📐 Formula'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuizMathText(
                    text: formula!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
          ],

          // MANIM video placeholder
          if (manimVideoUrl != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t(
                        vi: 'Video MANIM (sắp có)',
                        en: 'MANIM video (coming soon)',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
          ],

          // Explanation text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(vi: '💡 Lời giải', en: '💡 Solution'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                QuizMathText(
                  text: explanation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
