import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../review/data/models/spaced_review_item.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../../../schedule/data/models/study_schedule_item.dart';
import '../../../schedule/data/repositories/study_schedule_repository.dart';
import '../../../session/data/models/session_history_entry.dart';
import '../../../session/data/repositories/session_history_repository.dart';
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
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ListView(
          children: [
            _buildTopAppBar(context),
            const SizedBox(height: GrowMateLayout.sectionGap),
            Text(
              _vnDateLabel(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
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
            const SizedBox(height: GrowMateLayout.sectionGap),
            const _PhaseTwoQuickPanel(),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            Section(
              title: 'Tóm tắt',
              subtitle: 'Nhịp học hôm nay',
              backgroundColor: isDark
                  ? colors.surfaceContainerLow.withValues(alpha: 0.98)
                  : colors.surfaceContainerLow,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GrowMateLayout.space12,
                  vertical: GrowMateLayout.space8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Trang chủ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey<String>('ai-hero-thinking'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.contentGap,
        vertical: GrowMateLayout.contentGap,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
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
                color: colors.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.space12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.7 : 0.9,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật nhanh trong 24 giờ qua',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          SingleChildScrollView(
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
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: 0.74,
            backgroundColor: colors.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DA5A8)),
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
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Giữ lộ trình hiện tại',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.space12,
        vertical: GrowMateLayout.space12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
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
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
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

class _PhaseTwoQuickPanel extends StatelessWidget {
  const _PhaseTwoQuickPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ReviewDueStrip(),
        SizedBox(height: GrowMateLayout.space12),
        _MindfulBreakStrip(),
        SizedBox(height: GrowMateLayout.space12),
        _SchedulePriorityStrip(),
      ],
    );
  }
}

class _ReviewDueStrip extends StatelessWidget {
  const _ReviewDueStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();

    return StreamBuilder<List<SpacedReviewItem>>(
      stream: SpacedRepetitionRepository.instance.watchItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <SpacedReviewItem>[];
        final dueItems = items
            .where((item) => !item.dueAt.isAfter(now))
            .toList(growable: false);

        final title = dueItems.isEmpty
            ? 'Spaced Review hôm nay'
            : 'Có ${dueItems.length} chủ đề đến lịch ôn';
        final subtitle = dueItems.isEmpty
            ? 'Bạn đang giữ nhịp đều. Có thể bắt đầu phiên mới.'
            : 'Ưu tiên ôn: ${dueItems.first.topic}';

        return _QuickStrip(
          icon: Icons.refresh_rounded,
          title: title,
          subtitle: subtitle,
          onTap: () {
            context.push(AppRoutes.progress);
          },
        );
      },
    );
  }
}

class _MindfulBreakStrip extends StatelessWidget {
  const _MindfulBreakStrip();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionHistoryEntry>>(
      stream: SessionHistoryRepository.instance.watchHistory(),
      builder: (context, snapshot) {
        final history = snapshot.data ?? const <SessionHistoryEntry>[];
        final latest = history.isEmpty ? null : history.first;
        final shouldSuggestBreak =
            latest != null &&
            (latest.mode == 'recovery' || latest.focusScore < 3.0);

        final title = shouldSuggestBreak
            ? 'Gợi ý Mindful Break 90 giây'
            : 'Giữ nhịp ổn định';
        final subtitle = shouldSuggestBreak
            ? 'Phiên gần nhất cho thấy bạn nên nghỉ nhẹ trước khi học tiếp.'
            : 'Nếu thấy mệt, bạn vẫn có thể chủ động nghỉ thở 90 giây.';

        return _QuickStrip(
          icon: Icons.spa_rounded,
          title: title,
          subtitle: subtitle,
          onTap: () {
            context.push(AppRoutes.mindfulBreak);
          },
        );
      },
    );
  }
}

class _SchedulePriorityStrip extends StatelessWidget {
  const _SchedulePriorityStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<List<StudyScheduleItem>>(
      stream: StudyScheduleRepository.instance.watchItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <StudyScheduleItem>[];
        final pending =
            items.where((item) => !item.completed).toList(growable: false)
              ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

        final nearest = pending.isEmpty ? null : pending.first;
        final title = nearest == null
            ? 'Smart Schedule'
            : 'Mốc gần nhất: ${nearest.title}';

        final subtitle = nearest == null
            ? 'Thêm lịch thi/deadline để AI ưu tiên kế hoạch học.'
            : _scheduleSubtitle(nearest, now);

        return _QuickStrip(
          icon: Icons.calendar_month_rounded,
          title: title,
          subtitle: subtitle,
          onTap: () {
            context.push(AppRoutes.schedule);
          },
        );
      },
    );
  }

  static String _scheduleSubtitle(StudyScheduleItem item, DateTime now) {
    final daysLeft = item.dueAt.toLocal().difference(now).inDays;
    final label = item.type == 'exam' ? 'bài thi' : 'deadline';

    if (daysLeft <= 0) {
      return 'Hôm nay có $label, nên ưu tiên ôn ${item.subject} 15 phút.';
    }

    return 'Còn $daysLeft ngày tới $label (${item.subject}).';
  }
}

class _QuickStrip extends StatelessWidget {
  const _QuickStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: GrowMateColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
