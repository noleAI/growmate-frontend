import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9EF), Color(0xFFFFF2DD), Color(0xFFFFECCC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                Text(
                  'Chế độ phục hồi',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 36,
                    color: const Color(0xFF7C4A14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hít thở một nhịp ngắn. AI sẽ tự giảm nhịp học để bạn quay lại nhẹ nhàng hơn.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF8B5E2F),
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final message = _controller.value > 0.5
                        ? 'Hít vào thật sâu'
                        : 'Thở ra chậm rãi';

                    return Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 228,
                          height: 228,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFD7A5), Color(0xFFF5B971)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.28),
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
                              color: const Color(0xFF7C4A14),
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
                    'Tín hiệu phát hiện: ${_humanizeReason(widget.reason!)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9A6634),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Spacer(),
                ZenButton(
                  label: 'Mình sẵn sàng quay lại',
                  onPressed: _finishRecovery,
                  backgroundColor: const Color(0xFFF59E0B),
                  shadowColor: const Color(0xFFF59E0B),
                  textColor: Colors.white,
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _humanizeReason(String reason) {
    switch (reason) {
      case 'idle_time_high':
        return 'Mức tập trung giảm trong phiên vừa qua';
      case 'three_wrong_answers':
        return 'Bạn vừa gặp chuỗi câu khó liên tiếp';
      default:
        return reason;
    }
  }
}
