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

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

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
              title: 'Hôm nay nên làm gì tiếp?',
              subtitle:
                  '${_vnDateLabel(DateTime.now())} · Kế hoạch từ AI Agent',
              bottomSpacing: 0,
            ),
            const SizedBox(height: 16),
            AiRecommendationCard(
              topic: 'Đạo hàm ứng dụng',
              reason: 'AI nhận thấy bạn dễ mất điểm ở bài vận tốc tức thời.',
              confidence: 0.87,
              onStart: () => context.push(AppRoutes.quiz),
            ),
            const SizedBox(height: 16),
            const FadeSlideIn(delayMs: 80, child: _ProgressSnapshot()),
            const SizedBox(height: 14),
            InsightCard(
              title: 'Trạng thái học tập hiện tại',
              subtitle: 'AI đánh giá trước phiên học tiếp theo',
              delayMs: 120,
              child: const _MentalStateRow(),
            ),
            const SizedBox(height: 14),
            InsightCard(
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
          title: 'Snapshot',
          subtitle: 'Tình hình học tập trong 24h',
          bottomSpacing: 10,
        ),
        Row(
          children: const [
            Expanded(
              child: _MiniMetricCard(
                label: 'Streak',
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
                label: 'Focus',
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
        color: GrowMateColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            'AI đề xuất tăng dần độ khó, chưa cần kích hoạt recovery mode.',
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
      'Kiểm tra lại lỗi sai thường gặp ở bước biến đổi.',
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
