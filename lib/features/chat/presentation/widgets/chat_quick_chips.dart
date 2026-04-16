import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

class ChatQuickChips extends StatelessWidget {
  const ChatQuickChips({super.key, required this.onChipTapped});

  final ValueChanged<String> onChipTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final chips = [
      ('💡', context.t(vi: 'Giải thích', en: 'Explain')),
      ('📝', context.t(vi: 'Ví dụ khác', en: 'More examples')),
      ('🔄', context.t(vi: 'Đơn giản hơn', en: 'Simplify')),
      ('📊', context.t(vi: 'Bước tiếp', en: 'Next steps')),
      ('🧮', context.t(vi: 'Đạo hàm', en: 'Derivative')),
      ('📐', context.t(vi: 'Tích phân', en: 'Integral')),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (emoji, label) = chips[index];
          return ActionChip(
            avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
            label: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            backgroundColor: colors.surfaceContainerLow,
            onPressed: () => onChipTapped(label),
          );
        },
      ),
    );
  }
}
