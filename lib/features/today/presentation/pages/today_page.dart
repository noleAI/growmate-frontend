import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../inspection/presentation/cubit/inspection_cubit.dart';
import '../../../inspection/presentation/widgets/inspection_bottom_sheet.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? _thinkingTimer;
  bool _aiReady = false;

  @override
  void initState() {
    super.initState();
    _thinkingTimer = Timer(const Duration(milliseconds: 980), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _aiReady = true;
      });
    });
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            _buildTopAppBar(context),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Hệ thống AI học tập đang hoạt động',
              subtitle:
                  '${_vnDateLabel(DateTime.now())} · Quan sát -> quyết định -> dẫn dắt',
              bottomSpacing: 0,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 440),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _aiReady
                  ? AiRecommendationCard(
                      key: const ValueKey<String>('ai-recommendation-ready'),
                      topic: 'Ứng dụng đạo hàm theo tốc độ',
                      reason:
                          'Bạn giảm độ chính xác ở 2 câu tính giờ gần nhất.',
                      confidence: 0.87,
                      ctaLabel: 'Bắt đầu phiên tăng tốc cùng AI',
                      onStart: () => context.push(AppRoutes.quiz),
                    )
                  : const AiThinkingStateCard(
                      key: ValueKey<String>('ai-thinking'),
                      message: 'AI đang phân tích tiến độ của bạn...',
                    ),
            ),
            const SizedBox(height: 16),
            const FadeSlideIn(delayMs: 80, child: _ProgressSnapshot()),
            const SizedBox(height: 14),
            const _AiFeedbackTimeline(),
            const SizedBox(height: 14),
            AiInsightCard(
              title: 'Trạng thái học tập hiện tại',
              subtitle: 'Tín hiệu AI trước phiên học tiếp theo',
              delayMs: 120,
              child: const _MentalStateRow(),
            ),
            const SizedBox(height: 14),
            AiInsightCard(
              title: 'Bước tiếp theo',
              subtitle: 'Mục tiêu: hoàn thành trong 20 phút',
              delayMs: 160,
              child: const _NextActions(),
            ),
            const SizedBox(height: 8),
            Text(
              'Mẹo: Hoàn tất phiên này để AI cập nhật lộ trình can thiệp chính xác hơn.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.today,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    InspectionCubit? inspectionCubit;

    try {
      inspectionCubit = BlocProvider.of<InspectionCubit>(context);
    } catch (_) {
      inspectionCubit = null;
    }

    if (inspectionCubit == null) {
      return const GrowMateTopAppBar();
    }

    return StreamBuilder<InspectionState>(
      stream: inspectionCubit.stream,
      initialData: inspectionCubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? inspectionCubit!.state;

        return GrowMateTopAppBar(
          onInspectionTap: state.canInspect
              ? () {
                  InspectionBottomSheet.show(context);
                }
              : null,
        );
      },
    );
  }

  static String _vnDateLabel(DateTime now) {
    const weekdays = <int, String>{
      1: 'Thứ Hai',
      2: 'Thứ Ba',
      3: 'Thứ Tư',
      4: 'Thứ Năm',
      5: 'Thứ Sáu',
      6: 'Thứ Bảy',
      7: 'Chủ Nhật',
    };
    final weekday = weekdays[now.weekday] ?? 'Hôm nay';
    return '$weekday, ${now.day}/${now.month}';
  }
}

class _ProgressSnapshot extends StatelessWidget {
  const _ProgressSnapshot();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Tổng quan nhanh',
          subtitle: 'Tín hiệu hệ thống trong 24 giờ qua',
          bottomSpacing: 10,
        ),
        Row(
          children: const [
            Expanded(
              child: _MiniMetricCard(
                label: 'Chuỗi ngày',
                value: '6 ngày',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniMetricCard(
                label: 'Hoàn thành',
                value: '4/5',
                icon: Icons.task_alt_rounded,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniMetricCard(
                label: 'Tập trung',
                value: 'Tốt',
                icon: Icons.bolt_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GrowMateColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: GrowMateColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeedbackTimeline extends StatelessWidget {
  const _AiFeedbackTimeline();

  @override
  Widget build(BuildContext context) {
    return const AiInsightCard(
      title: 'Lớp phản hồi hệ thống AI',
      subtitle: 'Vòng lặp mô hình theo thời gian thực',
      delayMs: 108,
      child: Column(
        children: [
          _SystemStep(
            icon: Icons.visibility_rounded,
            label: 'Đã quan sát',
            detail:
                'Mô hình hành vi phát hiện tốc độ xử lý phần ứng dụng đạo hàm đang giảm.',
          ),
          SizedBox(height: 10),
          _SystemStep(
            icon: Icons.psychology_alt_rounded,
            label: 'Đã quyết định',
            detail:
                'Ưu tiên một phiên tăng tốc có hướng dẫn trước khi tăng độ khó.',
          ),
          SizedBox(height: 10),
          _SystemStep(
            icon: Icons.update_rounded,
            label: 'Đã cập nhật kế hoạch',
            detail: 'Chèn một vòng ôn ngắn + luyện tính giờ cho hôm nay.',
          ),
        ],
      ),
    );
  }
}

class _SystemStep extends StatelessWidget {
  const _SystemStep({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: GrowMateColors.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: GrowMateColors.primaryDark, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GrowMateColors.textSecondary,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MentalStateRow extends StatelessWidget {
  const _MentalStateRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: GrowMateColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Tập trung ổn định',
            style: TextStyle(
              color: GrowMateColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'AI gợi ý tăng độ khó nhẹ. Hiện tại chưa cần kích hoạt chế độ phục hồi.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextActions extends StatelessWidget {
  const _NextActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <String>[
      'Làm 3 câu ứng dụng đạo hàm có gợi ý.',
      'Rà lại bước biến đổi nơi lỗi lặp lại nhiều nhất.',
      'Kết thúc bằng 1 câu tự luận ngắn để AI chấm nhanh.',
    ];

    return Column(
      children: actions
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == actions.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GrowMateColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
