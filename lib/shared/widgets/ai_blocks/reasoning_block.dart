import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import 'ai_block_base.dart';
import 'ai_block_model.dart';

/// Block Type 2: Reasoning Chain — numbered evidence trail with uncertainty.
class ReasoningBlockWidget extends StatelessWidget {
  const ReasoningBlockWidget({
    super.key,
    required this.block,
    this.delayMs = 0,
    this.initiallyExpanded = false,
  });

  final ReasoningBlock block;
  final int delayMs;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(vi: 'Vì sao AI nghĩ vậy', en: 'Why AI thinks this'),
      accentColor: GrowMateColors.aiCore(theme.brightness).withValues(alpha: 0.7),
      delayMs: delayMs,
      child: _ReasoningBody(
        block: block,
        theme: theme,
        initiallyExpanded: initiallyExpanded,
      ),
    );
  }
}

class _ReasoningBody extends StatefulWidget {
  const _ReasoningBody({
    required this.block,
    required this.theme,
    required this.initiallyExpanded,
  });

  final ReasoningBlock block;
  final ThemeData theme;
  final bool initiallyExpanded;

  @override
  State<_ReasoningBody> createState() => _ReasoningBodyState();
}

class _ReasoningBodyState extends State<_ReasoningBody> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expand/collapse toggle
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: GrowMateColors.aiCore(brightness),
              ),
              const SizedBox(width: 6),
              Text(
                context.t(
                  vi: _expanded ? 'Ẩn chuỗi lập luận' : 'Xem chuỗi lập luận',
                  en: _expanded
                      ? 'Hide reasoning chain'
                      : 'View reasoning chain',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GrowMateColors.aiCore(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // Steps
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in widget.block.steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GrowMateColors.aiWhisper(brightness),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${step.index}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GrowMateColors.aiCore(brightness),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Uncertainty footer
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: GrowMateColors.uncertain(brightness),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.t(
                        vi: 'Độ không chắc chắn: ${(widget.block.uncertainty * 100).toStringAsFixed(0)}%',
                        en: 'Uncertainty: ${(widget.block.uncertainty * 100).toStringAsFixed(0)}%',
                      ),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: GrowMateColors.uncertain(brightness),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
