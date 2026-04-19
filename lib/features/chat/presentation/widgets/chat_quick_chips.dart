import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

class ChatQuickChips extends StatelessWidget {
  const ChatQuickChips({super.key, required this.onChipTapped});

  final ValueChanged<String> onChipTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final chips =
        <({IconData icon, String title, String subtitle, String prompt})>[
          (
            icon: Icons.fact_check_rounded,
            title: context.t(vi: 'Giải từng bước', en: 'Step-by-step'),
            subtitle: context.t(vi: 'Tách ý rõ ràng', en: 'Clear structure'),
            prompt: context.t(
              vi: 'Giải thích từng bước giúp mình.',
              en: 'Explain this step by step.',
            ),
          ),
          (
            icon: Icons.auto_stories_rounded,
            title: context.t(vi: 'Tóm tắt nhanh', en: 'Quick summary'),
            subtitle: context.t(vi: '3 ý quan trọng', en: '3 key ideas'),
            prompt: context.t(
              vi: 'Tóm tắt nhanh 3 ý quan trọng giúp mình.',
              en: 'Summarize the 3 key ideas for me.',
            ),
          ),
          (
            icon: Icons.switch_access_shortcut_add_rounded,
            title: context.t(vi: 'Ví dụ tương tự', en: 'Similar example'),
            subtitle: context.t(vi: 'Dễ hiểu hơn', en: 'Easier first'),
            prompt: context.t(
              vi: 'Cho mình một ví dụ tương tự nhưng dễ hơn.',
              en: 'Give me a similar but easier example.',
            ),
          ),
          (
            icon: Icons.functions_rounded,
            title: context.t(vi: 'Ôn công thức', en: 'Formula recap'),
            subtitle: context.t(vi: 'Nhớ thật nhanh', en: 'Recall faster'),
            prompt: context.t(
              vi: 'Nhắc lại công thức trọng tâm của phần này giúp mình.',
              en: 'Recap the core formulas for this topic.',
            ),
          ),
          (
            icon: Icons.trending_up_rounded,
            title: context.t(vi: 'Bước tiếp theo', en: 'Next move'),
            subtitle: context.t(vi: 'Nên học gì tiếp', en: 'What next'),
            prompt: context.t(
              vi: 'Mình nên làm bước tiếp theo như thế nào?',
              en: 'What should I do next?',
            ),
          ),
        ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChipTapped(chip.prompt),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(chip.icon, size: 14, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chip.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
