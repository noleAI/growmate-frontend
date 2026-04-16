import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import 'ai_block_base.dart';
import 'ai_block_model.dart';

/// Block Type 5: Status Update — informs user about automatic or pending changes.
class StatusBlockWidget extends StatelessWidget {
  const StatusBlockWidget({super.key, required this.block, this.delayMs = 0});

  final StatusUpdateBlock block;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(vi: 'Cập nhật', en: 'Update'),
      accentColor: GrowMateColors.aiPulse(Theme.of(context).brightness),
      delayMs: delayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          for (final change in block.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('– ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(
                      change.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                block.requiresConfirmation
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                block.requiresConfirmation
                    ? context.t(vi: 'Cần xác nhận', en: 'Needs confirmation')
                    : context.t(
                        vi: 'Tự động · Không cần đồng ý',
                        en: 'Automatic · No confirmation needed',
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
