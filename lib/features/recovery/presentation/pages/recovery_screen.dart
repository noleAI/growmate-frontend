import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/mood_state_service.dart';
import '../../../../features/quiz/presentation/cubit/quiz_cubit.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, this.reason});

  final String? reason;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accentSoft = Color(0xFFF6C78E);
  static const Color _accentStrong = Color(0xFFE9A35B);
  static const Color _accentSurface = Color(0xFFFFF6E8);

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
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Chế độ phục hồi',
              subtitle:
                  'AI giảm nhịp để giúp bạn lấy lại tập trung và sự tự tin',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accentSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Nhịp hồi phục',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _accentStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              bottomSpacing: 12,
            ),
            ZenCard(
              color: _accentSurface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Text(
                'Dành 1 phút để hít thở có hướng dẫn. Sau nhịp hồi phục này, AI sẽ tiếp tục với lộ trình nhẹ nhàng hơn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GrowMateColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _breathingScale,
                  builder: (context, child) {
                    final glow = 16 + ((_breathingScale.value - 0.88) * 76);

                    return Transform.scale(
                      scale: _breathingScale.value,
                      child: Container(
                        width: 186,
                        height: 186,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [_accentSoft, const Color(0xFFFFE6B9)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentStrong.withValues(alpha: 0.42),
                              blurRadius: glow,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _breathingScale.value > 0.98 ? 'Hít vào' : 'Thở ra',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF8A5418),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            ZenCard(
              color: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _accentSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.style_rounded,
                          color: _accentStrong,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Flashcard lúc này',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: GrowMateColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhắc nhanh: Đạo hàm của x^n là n.x^(n-1). Chốt chắc quy tắc này trước, rồi quay lại các câu tính giờ.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GrowMateColors.textSecondary,
                      height: 1.42,
                    ),
                  ),
                  if (widget.reason != null && widget.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tín hiệu ghi nhận: ${_humanizeReason(widget.reason!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _accentStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ZenButton(
              label: 'Mình đã sẵn sàng quay lại',
              onPressed: _finishRecovery,
              backgroundColor: _accentStrong,
              textColor: Colors.white,
              shadowColor: _accentStrong,
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
