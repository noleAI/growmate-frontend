import 'dart:math' as math;

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
  late final AnimationController _breathingController;
  late final Animation<double> _breathingScale;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _breathingScale = Tween<double>(begin: 0.88, end: 1.07).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
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
      backgroundColor: const Color(0xFFF9F2DE),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E5), Color(0xFFF7EDD8), Color(0xFFF3E7D0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Recovery Mode',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5F4F2F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mình thấy bạn cần một nhịp nghỉ nhẹ, tụi mình thở sâu cùng nhau nhé.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF7A6A49),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _breathingScale,
                      builder: (context, child) {
                        final glow = 16 + ((_breathingScale.value - 0.88) * 72);

                        return Transform.scale(
                          scale: _breathingScale.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFFE59E), Color(0xFFF5C978)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE7B566,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: glow,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _breathingScale.value > 0.98
                                  ? 'Hít vào'
                                  : 'Thở ra',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF6F5522),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFCEB078).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.style_rounded,
                            color: Color(0xFF7A5D2B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Flashcard of the day',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF6D5426),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhắc nhẹ: Đạo hàm của x^n là n.x^(n-1). Chỉ cần nhớ quy tắc này là bạn đã đi được nửa chặng rồi.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6E6143),
                          height: 1.45,
                        ),
                      ),
                      if (widget.reason != null &&
                          widget.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tín hiệu vừa ghi nhận: ${_humanizeReason(widget.reason!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8A7650),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ZenButton(
                  label: 'Mình sẵn sàng quay lại rồi',
                  onPressed: _finishRecovery,
                  trailing: Transform.rotate(
                    angle: math.pi / 14,
                    child: const Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.white,
                    ),
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
        return 'Mức tập trung giảm (idle_time cao)';
      case 'three_wrong_answers':
        return 'Bạn vừa gặp 3 câu khó liên tiếp';
      default:
        return reason;
    }
  }
}
