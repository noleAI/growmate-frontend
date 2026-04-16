import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../recovery/data/repositories/session_recovery_local.dart';
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

  final VoidCallback onResume;
  final VoidCallback onDismiss;
  final SessionRecoveryRepository? sessionRecoveryRepository;

  @override
  State<ResumeBanner> createState() => _ResumeBannerState();
}

class _ResumeBannerState extends State<ResumeBanner> {
  bool _hasPending = false;
  bool _dismissed = false;
  String? _pendingSessionId;

  @override
  void initState() {
    super.initState();
    _checkPending();
  }

  Future<void> _checkPending() async {
    // Try backend API first when available.
    final repo = widget.sessionRecoveryRepository;
    if (repo != null) {
      final pending = await repo.getPendingSession();
      if (mounted) {
        setState(() {
          _hasPending = pending.hasPending;
          _pendingSessionId = pending.sessionId;
        });
      }
      return;
    }

    // Fallback to local SharedPreferences.
    final pending = await SessionRecoveryLocal.hasPending();
    if (mounted) setState(() => _hasPending = pending);
  }

  /// The session ID from the backend, if available.
  String? get pendingSessionId => _pendingSessionId;

  @override
  Widget build(BuildContext context) {
    if (!_hasPending || _dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.t(
                  vi: 'Bạn còn bài dở! Tiếp tục nhé?',
                  en: 'You have an unfinished session! Continue?',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colors.onTertiaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                setState(() => _dismissed = true);
                SessionRecoveryLocal.clear();
                widget.onDismiss();
              },
              child: Text(context.t(vi: 'Bỏ', en: 'Skip')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.tertiary,
                foregroundColor: colors.onTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              onPressed: widget.onResume,
              child: Text(context.t(vi: 'Tiếp tục', en: 'Continue')),
            ),
          ],
        ),
      ),
    );
  }
}
