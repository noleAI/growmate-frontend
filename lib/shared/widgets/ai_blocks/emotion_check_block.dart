import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';
import 'ai_block_base.dart';
import 'ai_block_model.dart';

/// Block Type 4: Emotional Check — AI detected a mood shift, asking user to confirm.
class EmotionCheckBlockWidget extends StatelessWidget {
  const EmotionCheckBlockWidget({
    super.key,
    required this.block,
    this.delayMs = 0,
    this.onOptionSelected,
  });

  final EmotionCheckBlock block;
  final int delayMs;
  final ValueChanged<String>? onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(vi: 'Kiểm tra tâm trạng', en: 'Mood Check'),
      accentColor: GrowMateColors.confused(Theme.of(context).brightness),
      delayMs: delayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI observation message
          Text(
            block.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Emotion options as cards
          Text(
            context.t(vi: 'Bạn muốn:', en: 'You want to:'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < block.options.length; i++) ...[
                if (i > 0) const SizedBox(width: GrowMateLayout.space8),
                Expanded(
                  child: _EmotionOptionCard(
                    option: block.options[i],
                    onTap: () => onOptionSelected?.call(block.options[i].key),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Probability display
          if (block.probabilities.isNotEmpty) ...[
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(vi: 'AI ước lượng:', en: 'AI estimates:'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: block.probabilities.entries
                  .map((e) {
                    return Text(
                      '${e.key} ${(e.value * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmotionOptionCard extends StatelessWidget {
  const _EmotionOptionCard({required this.option, required this.onTap});

  final EmotionOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: GrowMateColors.surface2(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusSm),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
