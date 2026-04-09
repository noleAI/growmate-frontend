import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
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
    _thinkingTimer = Timer(const Duration(milliseconds: 880), () {
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
            const SizedBox(height: GrowMateLayout.sectionGap),
            Text(
              _vnDateLabel(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: GrowMateLayout.contentGap),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: _aiReady
                  ? AIHero(
                      key: const ValueKey<String>('ai-hero-ready'),
                      title: 'Bắt đầu phiên mới với',
                      topic: 'Ứng dụng đạo hàm',
                      reason:
                          'AI ghi nhận độ chính xác câu tính giờ đang giảm trong 2 phiên gần nhất.',
                      confidence: 0.87,
                      ctaLabel: 'Bắt đầu phiên AI gợi ý',
                      onPressed: () => context.push(AppRoutes.quiz),
                    )
                  : _ThinkingHero(theme: theme),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            const Section(
              title: 'Tóm tắt',
              subtitle: 'Nhịp học hôm nay',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_CompactStats()],
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            const Section(
              title: 'Phân tích AI hoàn tất',
              subtitle: 'Độ tự tin 74% · Rủi ro TRUNG BÌNH',
              child: _AiSystemPanel(),
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
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

class _ThinkingHero extends StatelessWidget {
  const _ThinkingHero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('ai-hero-thinking'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.contentGap,
        vertical: GrowMateLayout.contentGap,
      ),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(width: GrowMateLayout.space12),
          Expanded(
            child: Text(
              'AI đang phân tích tiến độ của bạn...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStats extends StatelessWidget {
  const _CompactStats();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          StatItem(
            label: 'ngày',
            value: '6',
            icon: Icons.local_fire_department_rounded,
            accent: Color(0xFFEA580C),
          ),
          SizedBox(width: GrowMateLayout.space12),
          StatItem(
            label: 'hoàn thành',
            value: '4/5',
            icon: Icons.task_alt_rounded,
            accent: GrowMateColors.success,
          ),
          SizedBox(width: GrowMateLayout.space12),
          StatItem(
            label: 'Tập trung',
            value: 'Tốt',
            icon: Icons.bolt_rounded,
            accent: GrowMateColors.primary,
          ),
        ],
      ),
    );
  }
}

class _AiSystemPanel extends StatelessWidget {
  const _AiSystemPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            minHeight: 6,
            value: 0.74,
            backgroundColor: GrowMateColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DA5A8)),
          ),
        ),
        const SizedBox(height: GrowMateLayout.contentGap),
        const _InsightTile(
          icon: Icons.check_circle_rounded,
          iconColor: GrowMateColors.success,
          title: 'Bạn làm tốt ở điểm nào',
          subtitle: 'Quy tắc đạo hàm cơ bản',
        ),
        const SizedBox(height: GrowMateLayout.space12),
        const _InsightTile(
          icon: Icons.warning_amber_rounded,
          iconColor: GrowMateColors.warningSoft,
          title: 'Điểm cần cải thiện',
          subtitle: 'Đạo hàm hàm số hợp',
        ),
        const SizedBox(height: GrowMateLayout.space12),
        const _InsightTile(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: GrowMateColors.primary,
          title: 'Bước tiếp theo AI gợi ý',
          subtitle: 'Review đạo hàm',
        ),
        const SizedBox(height: GrowMateLayout.contentGap),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: GrowMateLayout.contentGap,
            vertical: GrowMateLayout.space12,
          ),
          decoration: BoxDecoration(
            color: GrowMateColors.backgroundSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Giữ lộ trình hiện tại',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: GrowMateColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.space12,
        vertical: GrowMateLayout.space12,
      ),
      decoration: BoxDecoration(
        color: GrowMateColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: GrowMateLayout.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
