import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../recovery/data/repositories/session_recovery_local.dart';
import '../../../session_recovery/data/models/pending_session.dart';

/// Presentational banner shown when a pending study session can be resumed.
class ResumeBanner extends StatelessWidget {
  const ResumeBanner({
    super.key,
    required this.pendingSession,
    required this.onResume,
    required this.onDismiss,
  });

  final PendingSession pendingSession;
  final ValueChanged<PendingSession> onResume;
  final VoidCallback onDismiss;

  String _modeLabel(BuildContext context, String? mode) {
    switch ((mode ?? '').trim().toLowerCase()) {
      case 'recovery':
        return context.t(vi: 'Phục hồi', en: 'Recovery');
      case 'academic':
        return context.t(vi: 'Học tập', en: 'Academic');
      default:
        return context.t(vi: 'Phiên học', en: 'Study session');
    }
  }

  String _progressLabel(BuildContext context, PendingSession session) {
    final progress = session.progressPercent;
    if (progress != null) {
      return context.t(vi: '$progress% hoàn thành', en: '$progress% complete');
    }

    final total = session.totalQuestions;
    final nextIndex = session.nextQuestionIndex ?? session.lastQuestionIndex;
    if (total != null && total > 0 && nextIndex != null && nextIndex >= 0) {
      final derived = (((nextIndex + 1) / total) * 100).clamp(0, 100).toInt();
      return context.t(vi: '$derived% hoàn thành', en: '$derived% complete');
    }

    return context.t(vi: 'Đang chờ tiếp tục', en: 'Ready to resume');
  }

  String _nextQuestionLabel(BuildContext context, PendingSession session) {
    final nextIndex = session.nextQuestionIndex ?? session.lastQuestionIndex;
    final total = session.totalQuestions;
    if (nextIndex == null || nextIndex < 0) {
      return context.t(
        vi: 'Câu tiếp theo chưa rõ',
        en: 'Next question unknown',
      );
    }

    final questionNumber = nextIndex + 1;
    if (total != null && total > 0) {
      return context.t(
        vi: 'Câu $questionNumber/$total',
        en: 'Question $questionNumber/$total',
      );
    }

    return context.t(vi: 'Câu $questionNumber', en: 'Question $questionNumber');
  }

  String _lastActiveLabel(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.t(vi: 'Chưa có dữ liệu', en: 'No activity data');
    }

    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return context.t(vi: '$date • $time', en: '$date • $time');
  }

  @override
  Widget build(BuildContext context) {
    if (!pendingSession.hasPending) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final modeLabel = _modeLabel(context, pendingSession.mode);
    final progressLabel = _progressLabel(context, pendingSession);
    final nextQuestionLabel = _nextQuestionLabel(context, pendingSession);
    final lastActiveLabel = _lastActiveLabel(
      context,
      pendingSession.lastActiveAt,
    );
    final pauseReason = pendingSession.pauseReason?.trim();

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t(
                      vi: 'Bạn có một phiên học đang dở',
                      en: 'You have an unfinished session',
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ResumeInfoChip(
                  label: modeLabel,
                  foreground: colors.onTertiaryContainer,
                  background: colors.tertiary.withValues(alpha: 0.22),
                ),
                _ResumeInfoChip(
                  label: progressLabel,
                  foreground: colors.onTertiaryContainer,
                  background: colors.surface.withValues(alpha: 0.48),
                ),
                _ResumeInfoChip(
                  label: nextQuestionLabel,
                  foreground: colors.onTertiaryContainer,
                  background: colors.surface.withValues(alpha: 0.48),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                vi: 'Hoạt động gần nhất: $lastActiveLabel',
                en: 'Last active: $lastActiveLabel',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (pauseReason != null && pauseReason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                context.t(
                  vi: 'Lý do tạm dừng: $pauseReason',
                  en: 'Pause reason: $pauseReason',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onTertiaryContainer.withValues(alpha: 0.86),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onTertiaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () async {
                    await SessionRecoveryLocal.clear();
                    onDismiss();
                  },
                  child: Text(
                    context.t(vi: 'Bỏ phiên này', en: 'Discard session'),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.tertiary,
                    foregroundColor: colors.onTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () => onResume(pendingSession),
                  child: Text(
                    context.t(vi: 'Tiếp tục bài dở', en: 'Resume now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeInfoChip extends StatelessWidget {
  const _ResumeInfoChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
