import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../recovery/data/repositories/session_recovery_local.dart';
import '../../../session_recovery/data/models/pending_session.dart';
import '../../../session_recovery/data/repositories/session_recovery_repository.dart';

/// Banner hiển thị khi có phiên học còn dở dang.
///
/// Checks the backend API via [SessionRecoveryRepository] when provided,
/// falling back to local SharedPreferences via [SessionRecoveryLocal].
class ResumeBanner extends StatefulWidget {
  const ResumeBanner({
    super.key,
    required this.onResume,
    required this.onDismiss,
    this.sessionRecoveryRepository,
  });

  final ValueChanged<PendingSession> onResume;
  final VoidCallback onDismiss;
  final SessionRecoveryRepository? sessionRecoveryRepository;

  @override
  State<ResumeBanner> createState() => _ResumeBannerState();
}

class _ResumeBannerState extends State<ResumeBanner> {
  bool _hasPending = false;
  bool _dismissed = false;
  PendingSession? _pendingSession;

  @override
  void initState() {
    super.initState();
    _checkPending();
  }

  Future<void> _checkPending() async {
    LocalPendingSession? localFallback;

    // Try backend API first when available.
    final repo = widget.sessionRecoveryRepository;
    if (repo != null) {
      try {
        final pending = await repo.getPendingSession();
        if (pending.hasPending) {
          if (mounted) {
            setState(() {
              _hasPending = true;
              _pendingSession = pending;
            });
          }
          return;
        }

        // Backend is the source of truth. If there is no pending session,
        // clear local fallback state to avoid stale resume prompts.
        await SessionRecoveryLocal.clear();
        if (mounted) {
          setState(() {
            _hasPending = false;
            _pendingSession = null;
          });
        }
        return;
      } catch (_) {
        // Network/backend error -> try validated local fallback.
      }
    }

    // Fallback to local SharedPreferences with freshness + metadata checks.
    localFallback = await SessionRecoveryLocal.loadFreshSnapshot();

    if (mounted) {
      setState(() {
        _hasPending = localFallback != null;
        _pendingSession = localFallback == null
            ? null
            : PendingSession(
                hasPending: true,
                sessionId: localFallback.sessionId,
                status: localFallback.status,
                lastQuestionIndex: localFallback.lastQuestionIndex,
                nextQuestionIndex: localFallback.lastQuestionIndex,
                totalQuestions: localFallback.totalQuestions,
                progressPercent: localFallback.totalQuestions > 0
                    ? ((localFallback.lastQuestionIndex + 1) /
                              localFallback.totalQuestions *
                              100)
                          .clamp(0, 100)
                          .toInt()
                    : null,
                mode: 'academic',
                pauseState: false,
                pauseReason: null,
                resumeContextVersion: 1,
                lastActiveAt: localFallback.updatedAt,
                abandonedAt: null,
              );
      });
    }
  }

  /// The session ID from the backend, if available.
  String? get pendingSessionId => _pendingSession?.sessionId;

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
    if (!_hasPending || _dismissed) return const SizedBox.shrink();

    final session = _pendingSession;
    if (session == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final modeLabel = _modeLabel(context, session.mode);
    final progressLabel = _progressLabel(context, session);
    final nextQuestionLabel = _nextQuestionLabel(context, session);
    final lastActiveLabel = _lastActiveLabel(context, session.lastActiveAt);
    final pauseReason = session.pauseReason?.trim();

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
                    setState(() => _dismissed = true);
                    await SessionRecoveryLocal.clear();
                    widget.onDismiss();
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
                  onPressed: () => widget.onResume(session),
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
