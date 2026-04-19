import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../chat/presentation/cubit/chat_quota_cubit.dart';
import '../../../chat/presentation/cubit/chat_quota_state.dart';

/// Small badge showing remaining chat quota (e.g. "💬 15").
///
/// Turns red when quota is low (≤ 3) and shows "0" when exhausted.
class QuotaIndicator extends StatelessWidget {
  const QuotaIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<ChatQuotaCubit, ChatQuotaState>(
      builder: (context, state) {
        if (state is! ChatQuotaLoaded) {
          return const SizedBox.shrink();
        }

        final remaining = state.quota.remaining;
        final isLow = remaining <= 3;
        final badgeColor = isLow
            ? colors.errorContainer
            : colors.surfaceContainerHigh;
        final textColor = isLow
            ? colors.onErrorContainer
            : colors.onSurfaceVariant;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isLow
                  ? colors.error.withValues(alpha: 0.3)
                  : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_rounded, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                '$remaining',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A text field with character limit counter for chat input.
///
/// Enforces [maxLength] of 300 characters as per token management policy.
class QuotaLimitedTextField extends StatelessWidget {
  const QuotaLimitedTextField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.maxLength = 300,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final int maxLength;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLength: maxLength,
      enabled: enabled,
      maxLines: null,
      textInputAction: TextInputAction.send,
      onSubmitted: enabled ? onSubmitted : null,
      decoration: InputDecoration(
        hintText: context.t(
          vi: 'Nhập câu hỏi toán...',
          en: 'Ask a math question...',
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        counterStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      ),
    );
  }
}
