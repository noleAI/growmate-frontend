import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';
import '../ai_blocks/ai_block_model.dart';
import '../ai_blocks/block_renderer.dart';
import '../ai_orb/ai_orb_state.dart';
import '../confidence/confidence_label.dart';

/// The AI Companion bottom sheet — the primary AI interaction surface.
///
/// Slides up from the AI Orb. Contains structured AI blocks (not message bubbles)
/// plus an optional free-text input at the bottom.
class AiCompanionSheet extends StatelessWidget {
  const AiCompanionSheet({
    super.key,
    required this.blocks,
    required this.orbState,
    required this.confidence,
    this.onDecisionAccept,
    this.onDecisionReject,
    this.onDecisionAskWhy,
    this.onDecisionModify,
    this.onEmotionSelected,
    this.onTextSubmitted,
  });

  final List<AiBlock> blocks;
  final AiOrbState orbState;
  final double confidence;
  final VoidCallback? onDecisionAccept;
  final VoidCallback? onDecisionReject;
  final VoidCallback? onDecisionAskWhy;
  final VoidCallback? onDecisionModify;
  final ValueChanged<String>? onEmotionSelected;
  final ValueChanged<String>? onTextSubmitted;

  /// Shows the companion sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<AiBlock> blocks,
    AiOrbState orbState = AiOrbState.idle,
    double confidence = 0.0,
    VoidCallback? onDecisionAccept,
    VoidCallback? onDecisionReject,
    VoidCallback? onDecisionAskWhy,
    VoidCallback? onDecisionModify,
    ValueChanged<String>? onEmotionSelected,
    ValueChanged<String>? onTextSubmitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        snap: true,
        snapSizes: const [0.5, 0.88],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: AiCompanionSheet(
              blocks: blocks,
              orbState: orbState,
              confidence: confidence,
              onDecisionAccept: onDecisionAccept,
              onDecisionReject: onDecisionReject,
              onDecisionAskWhy: onDecisionAskWhy,
              onDecisionModify: onDecisionModify,
              onEmotionSelected: onEmotionSelected,
              onTextSubmitted: onTextSubmitted,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // AI avatar circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.aiCore(theme.brightness),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GrowMate AI',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ConfidenceLabel(confidence: confidence),
                  ],
                ),
              ),
              // Status indicator
              _OrbStatusDot(state: orbState),
            ],
          ),
        ),

        Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),

        // Block list
        Expanded(
          child: blocks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      context.t(
                        vi: 'AI đang phân tích...',
                        en: 'AI is analyzing...',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: blocks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final delay = (index * 100).clamp(0, 800);
                    return AiBlockRenderer(
                      block: blocks[index],
                      delayMs: delay,
                      onDecisionAccept: onDecisionAccept,
                      onDecisionReject: onDecisionReject,
                      onDecisionAskWhy: onDecisionAskWhy,
                      onDecisionModify: onDecisionModify,
                      onEmotionSelected: onEmotionSelected,
                    );
                  },
                ),
        ),

        // Text input bar
        if (onTextSubmitted != null)
          _ChatInputBar(onSubmitted: onTextSubmitted!),
      ],
    );
  }
}

class _OrbStatusDot extends StatelessWidget {
  const _OrbStatusDot({required this.state});

  final AiOrbState state;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = switch (state) {
      AiOrbState.thinking => GrowMateColors.aiPulse(brightness),
      AiOrbState.hasSuggestion => GrowMateColors.aiCore(brightness),
      AiOrbState.uncertain => GrowMateColors.uncertain(brightness),
      AiOrbState.error => GrowMateColors.lowConfidence(brightness),
      _ => GrowMateColors.aiCore(brightness).withValues(alpha: 0.5),
    };

    final label = switch (state) {
      AiOrbState.thinking => context.t(vi: 'Đang xử lý', en: 'Processing'),
      AiOrbState.hasSuggestion => context.t(vi: 'Có gợi ý', en: 'Has suggestion'),
      AiOrbState.uncertain => context.t(vi: 'Cần ý kiến', en: 'Needs input'),
      AiOrbState.error => context.t(vi: 'Lỗi', en: 'Error'),
      _ => context.t(vi: 'Hoạt động', en: 'Active'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: GrowMateColors.surface2(theme.brightness),
                  borderRadius: BorderRadius.circular(
                    GrowMateLayout.cardRadiusSm,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _submit(),
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: context.t(
                      vi: 'Hỏi AI bất cứ điều gì...',
                      en: 'Ask AI anything...',
                    ),
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.aiCore(theme.brightness),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
