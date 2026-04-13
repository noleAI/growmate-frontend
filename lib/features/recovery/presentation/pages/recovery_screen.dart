import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/services/mood_state_service.dart';
import '../../../../features/quiz/presentation/cubit/quiz_cubit.dart';
import '../../../../shared/widgets/zen_button.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, this.reason});

  final String? reason;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.9,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finishRecovery() {
    MoodStateService.instance.setMood('Focused');
    QuizCubit.resetWrongStreak();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerLow,
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHigh,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: context.t(vi: 'Đóng', en: 'Close'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(vi: 'Chế độ phục hồi', en: 'Recovery mode'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(
                    vi: 'Hít thở một nhịp ngắn. AI sẽ tự giảm nhịp học để bạn quay lại nhẹ nhàng hơn.',
                    en: 'Take a short breathing pause. AI will gently reduce study intensity to help you return smoothly.',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final message = _controller.value > 0.5
                        ? context.t(
                            vi: 'Hít vào thật sâu',
                            en: 'Breathe in deeply',
                          )
                        : context.t(
                            vi: 'Thở ra chậm rãi',
                            en: 'Breathe out slowly',
                          );

                    return Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 228,
                          height: 228,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.secondaryContainer,
                                theme.colorScheme.secondaryContainer.withValues(
                                  alpha: 0.85,
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                if (widget.reason != null && widget.reason!.isNotEmpty)
                  Text(
                    context.t(
                      vi: 'Tín hiệu phát hiện: ${_humanizeReason(context, widget.reason!)}',
                      en: 'Detected signal: ${_humanizeReason(context, widget.reason!)}',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Spacer(),
                ZenButton(
                  label: context.t(
                    vi: 'Mình sẵn sàng quay lại',
                    en: 'I am ready to return',
                  ),
                  onPressed: _finishRecovery,
                  backgroundColor: theme.colorScheme.secondary,
                  shadowColor: theme.colorScheme.secondary,
                  textColor: theme.colorScheme.onSecondary,
                  trailing: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _humanizeReason(BuildContext context, String reason) {
    switch (reason) {
      case 'idle_time_high':
        return context.t(
          vi: 'Mức tập trung giảm trong phiên vừa qua',
          en: 'Focus level dropped in the recent session',
        );
      case 'three_wrong_answers':
        return context.t(
          vi: 'Bạn vừa gặp chuỗi câu khó liên tiếp',
          en: 'You hit a sequence of difficult questions',
        );
      default:
        return context.t(
          vi: 'AI phát hiện bạn cần nghỉ ngơi một chút',
          en: 'AI detected you could use a short break',
        );
    }
  }
}
