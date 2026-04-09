import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class MindfulBreakPage extends StatefulWidget {
  const MindfulBreakPage({super.key});

  @override
  State<MindfulBreakPage> createState() => _MindfulBreakPageState();
}

class _MindfulBreakPageState extends State<MindfulBreakPage> {
  static const int _totalSeconds = 90;
  static const int _cycleSeconds = 8;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) {
        _timer?.cancel();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go(AppRoutes.home);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GrowMateColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Mindful Break',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
            Text(
              'Dành 90 giây để hít thở nhẹ, giúp hệ thần kinh ổn định trước khi quay lại học.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          GrowMateColors.primary,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeInOut,
                      width: _phaseScale(),
                      height: _phaseScale(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GrowMateColors.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phaseLabel(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: GrowMateColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatSeconds(_remainingSeconds),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: GrowMateColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            ZenCard(
              radius: 20,
              child: Text(
                _remainingSeconds == 0
                    ? 'Tuyệt vời. Bạn vừa reset nhịp thở thành công, giờ có thể quay lại phiên học nhé.'
                    : 'Gợi ý: hít sâu bằng mũi 4 giây, thở ra chậm 4 giây. Không cần cố gắng quá, chỉ cần đều nhịp.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
            ZenButton(
              label: _remainingSeconds == 0
                  ? 'Quay lại lộ trình học'
                  : 'Kết thúc break nhẹ nhàng',
              onPressed: () {
                context.go(AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel() {
    if (_remainingSeconds == 0) {
      return 'Hoàn thành';
    }

    final elapsed = _totalSeconds - _remainingSeconds;
    final inCycle = elapsed % _cycleSeconds;
    return inCycle < 4 ? 'Hít vào' : 'Thở ra';
  }

  double _phaseScale() {
    if (_remainingSeconds == 0) {
      return 120;
    }

    final elapsed = _totalSeconds - _remainingSeconds;
    final inCycle = elapsed % _cycleSeconds;
    return inCycle < 4 ? 126 : 104;
  }

  static String _formatSeconds(int value) {
    final minutes = (value ~/ 60).toString().padLeft(2, '0');
    final seconds = (value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
