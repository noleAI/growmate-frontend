import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';
import '../zen_button.dart';
import 'ai_block_base.dart';
import 'ai_block_model.dart';

/// Block Type 3: Decision — HITL accept/reject/modify/askWhy.
class DecisionBlockWidget extends StatelessWidget {
  const DecisionBlockWidget({
    super.key,
    required this.block,
    this.delayMs = 0,
    this.onAccept,
    this.onReject,
    this.onAskWhy,
    this.onModify,
  });

  final DecisionBlock block;
  final int delayMs;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onAskWhy;
  final VoidCallback? onModify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final priorityColor = switch (block.priority) {
      BlockPriority.high => GrowMateColors.lowConfidence(brightness),
      BlockPriority.medium => GrowMateColors.uncertain(brightness),
      BlockPriority.low => GrowMateColors.aiCore(brightness),
    };
    final priorityLabel = switch (block.priority) {
      BlockPriority.high => context.t(vi: 'CAO', en: 'HIGH'),
      BlockPriority.medium => context.t(vi: 'TB', en: 'MED'),
      BlockPriority.low => context.t(vi: 'THẤP', en: 'LOW'),
    };

    return AiBlockBase(
      blockLabel: context.t(vi: 'AI đề xuất', en: 'AI Suggestion'),
      accentColor: GrowMateColors.aiCore(brightness),
      delayMs: delayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendation headline
          Text(
            '${context.t(vi: 'Bước tiếp', en: 'Next step')}: ${block.recommendation}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Meta: duration + priority
          Row(
            children: [
              if (block.duration != null) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  block.duration!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${context.t(vi: 'Ưu tiên', en: 'Priority')}: $priorityLabel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason
          Text(
            block.reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (block.status == DecisionStatus.pending) ...[
            // Primary: Accept
            ZenButton(
              label: context.t(
                vi: 'Đồng ý lộ trình này',
                en: 'Accept this plan',
              ),
              onPressed: onAccept,
              leading: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: GrowMateLayout.space8),

            // Secondary row: Reject + Ask Why
            Row(
              children: [
                Expanded(
                  child: ZenButton(
                    label: context.t(vi: 'Không', en: 'No'),
                    variant: ZenButtonVariant.secondary,
                    onPressed: onReject,
                    leading: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: GrowMateLayout.space8),
                Expanded(
                  child: ZenButton(
                    label: context.t(vi: 'Vì sao gợi ý?', en: 'Why this?'),
                    variant: ZenButtonVariant.secondary,
                    onPressed: onAskWhy,
                    leading: Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowMateLayout.space8),

            // Modify
            ZenButton(
              label: context.t(
                vi: 'Mình muốn học cái khác',
                en: 'I want something else',
              ),
              variant: ZenButtonVariant.text,
              onPressed: onModify,
              leading: Icon(
                Icons.edit_rounded,
                size: 16,
                color: GrowMateColors.aiCore(brightness),
              ),
            ),
          ] else ...[
            // Status badge when decided
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: GrowMateColors.aiWhisper(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    block.status == DecisionStatus.accepted
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    size: 18,
                    color: block.status == DecisionStatus.accepted
                        ? GrowMateColors.confident(brightness)
                        : GrowMateColors.uncertain(brightness),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: block.status == DecisionStatus.accepted
                          ? GrowMateColors.confident(brightness)
                          : GrowMateColors.uncertain(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    return switch (block.status) {
      DecisionStatus.accepted => context.t(vi: 'Đã đồng ý', en: 'Accepted'),
      DecisionStatus.rejected => context.t(vi: 'Đã từ chối', en: 'Rejected'),
      DecisionStatus.modified => context.t(vi: 'Đã chỉnh sửa', en: 'Modified'),
      DecisionStatus.pending => '',
    };
  }
}
