import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../review/data/models/spaced_review_item.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../../../schedule/data/models/study_schedule_item.dart';
import '../../../schedule/data/repositories/study_schedule_repository.dart';
import '../../../session/data/models/session_history_entry.dart';
import '../../../session/data/repositories/session_history_repository.dart';
import '../../../diagnosis/data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
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
  bool _onboardingDismissed = true;

  static const String _onboardingKey = 'onboarding_dismissed';

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
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingDismissed = prefs.getBool(_onboardingKey) ?? false;
    });
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    if (!mounted) return;
    setState(() {
      _onboardingDismissed = true;
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

    return StreamBuilder<List<SessionHistoryEntry>>(
      stream: SessionHistoryRepository.instance.watchHistory(),
      builder: (context, snapshot) {
        final history = snapshot.data ?? const <SessionHistoryEntry>[];
        final latestSession = history.isEmpty ? null : history.first;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: ZenPageContainer(
            includeBottomSafeArea: false,
            child: ListView(
              children: [
                _buildTopAppBar(context),
                const SizedBox(height: GrowMateLayout.space16),
                Text(
                  _dateLabel(context, DateTime.now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (latestSession != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _MentalStateChip(
                      focusScore: latestSession.focusScore,
                    ),
                  ),
                const SizedBox(height: GrowMateLayout.contentGap),
                if (history.isEmpty && !_onboardingDismissed) ...[
                  _OnboardingCard(onDismiss: _dismissOnboarding),
                  const SizedBox(height: GrowMateLayout.space12),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: _aiReady
                      ? _buildHero(context, latestSession)
                      : _ThinkingHero(theme: theme),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                const _PhaseTwoQuickPanel(),
                const SizedBox(height: GrowMateLayout.space16),
                Section(
                  title: context.t(vi: 'Tóm tắt', en: 'Summary'),
                  subtitle: context.t(
                    vi: 'Nhịp học hôm nay',
                    en: 'Today learning rhythm',
                  ),
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
                      context.t(vi: 'Trang chủ', en: 'Home'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_CompactStats(history: history)],
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space16),
                const _AiAnalysisSection(),
                const SizedBox(height: GrowMateLayout.sectionGap),
              ],
            ),
          ),
          bottomNavigationBar: GrowMateBottomNavBar(
            currentTab: GrowMateTab.today,
            onTabSelected: (tab) => handleTabNavigation(context, tab),
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, SessionHistoryEntry? latestSession) {
    if (latestSession == null) {
      return const _EmptyHeroCard();
    }

    return AIHero(
      key: const ValueKey<String>('ai-hero-ready'),
      title: context.t(
        vi: 'Bắt đầu phiên mới với',
        en: 'Start a new session with',
      ),
      topic: latestSession.topic.trim().isEmpty
          ? context.t(vi: 'Đạo hàm cơ bản', en: 'Basic Derivatives')
          : latestSession.topic,
      reason: latestSession.nextAction.trim().isEmpty
          ? context.t(
              vi: 'AI cập nhật gợi ý sau phiên tiếp theo.',
              en: 'AI updates after your next session.',
            )
          : latestSession.nextAction,
      confidence: latestSession.confidenceScore.clamp(0.0, 1.0),
      ctaLabel: context.t(vi: 'Bắt đầu phiên mới', en: 'Start session'),
      onPressed: () => context.push(AppRoutes.quiz),
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
      return const GrowMateTopAppBar(appleStyle: true);
    }

    return StreamBuilder<InspectionState>(
      stream: inspectionCubit.stream,
      initialData: inspectionCubit.state,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorStateWidget(
            message: context.t(
              vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
              en: 'Unable to load data. Please try again.',
            ),
            onRetry: () {
              setState(() {});
            },
          );
        }

        if (!snapshot.hasData) {
          return const _LoadingStateWidget();
        }

        final state = snapshot.data ?? inspectionCubit!.state;

        return GrowMateTopAppBar(
          appleStyle: true,
          showInsightInDev: state.devModeEnabled,
          onInspectionTap: state.canInspect
              ? () {
                  InspectionBottomSheet.show(context);
                }
              : null,
        );
      },
    );
  }

  static String _dateLabel(BuildContext context, DateTime now) {
    if (context.isEnglish) {
      const weekdays = <int, String>{
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      };
      final weekday = weekdays[now.weekday] ?? 'Today';
      return '$weekday, ${now.day}/${now.month}';
    }

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
              context.t(
                vi: 'AI đang phân tích tiến độ của bạn...',
                en: 'AI is analyzing your progress...',
              ),
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

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      key: const ValueKey<String>('ai-hero-empty'),
      radius: 22,
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: colors.primary),
              const SizedBox(width: GrowMateLayout.space8),
              Text(
                context.t(
                  vi: 'AI gợi ý phiên mới',
                  en: 'AI session suggestion',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            context.t(
              vi: 'Hoàn thành phiên đầu tiên để AI phân tích!',
              en: 'Complete your first session for AI insights!',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(vi: 'Bắt đầu ngay', en: 'Get started'),
            onPressed: () => context.push(AppRoutes.quiz),
          ),
        ],
      ),
    );
  }
}

class _AiAnalysisSection extends StatelessWidget {
  const _AiAnalysisSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DiagnosisSnapshot?>(
      future: DiagnosisSnapshotCacheRepository.instance.readSnapshot(),
      builder: (context, snapshot) {
        final cached = snapshot.data;
        final subtitle = cached == null
            ? context.t(
                vi: 'Chưa có dữ liệu phân tích',
                en: 'No AI analysis yet',
              )
            : context.t(
                vi: 'Độ tự tin ${(cached.confidenceScore.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                en: 'Confidence ${(cached.confidenceScore.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
              );

        return Section(
          title: context.t(
            vi: 'Phân tích AI gần nhất',
            en: 'Latest AI analysis',
          ),
          subtitle: subtitle,
          child: snapshot.connectionState == ConnectionState.waiting
              ? const _LoadingStateWidget()
              : _AiSystemPanel(snapshot: cached),
        );
      },
    );
  }
}

class _CompactStats extends StatelessWidget {
  const _CompactStats({required this.history});

  final List<SessionHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final streak = _calculateStreak(history, now);
    final sessionsToday = _sessionsToday(history, now);
    final sessionsLast24h = _sessionsLast24Hours(history, now);
    final focusLabel = _focusLabel(context, history, now);

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
            context.t(vi: '24 giờ qua', en: 'Last 24 hours'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatItem(
                  label: context.t(vi: 'ngày', en: 'days'),
                  value: '$streak',
                  icon: Icons.local_fire_department_rounded,
                  accent: colors.tertiary,
                ),
                const SizedBox(width: GrowMateLayout.space12),
                StatItem(
                  label: context.t(vi: 'hoàn thành', en: 'completed'),
                  value: '$sessionsToday/$sessionsLast24h',
                  icon: Icons.task_alt_rounded,
                  accent: colors.tertiary,
                ),
                const SizedBox(width: GrowMateLayout.space12),
                StatItem(
                  label: context.t(vi: 'Tập trung', en: 'Focus'),
                  value: focusLabel,
                  icon: Icons.bolt_rounded,
                  accent: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _calculateStreak(List<SessionHistoryEntry> entries, DateTime now) {
    if (entries.isEmpty) {
      return 0;
    }

    final activeDays = entries
        .map((entry) => _dateOnly(entry.completedAt.toLocal()))
        .toSet();

    var streak = 0;
    var cursor = _dateOnly(now);
    while (activeDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _sessionsToday(List<SessionHistoryEntry> entries, DateTime now) {
    final today = _dateOnly(now);
    return entries.where((entry) {
      final entryDay = _dateOnly(entry.completedAt.toLocal());
      return entryDay == today;
    }).length;
  }

  static int _sessionsLast24Hours(
    List<SessionHistoryEntry> entries,
    DateTime now,
  ) {
    final threshold = now.toUtc().subtract(const Duration(hours: 24));
    return entries
        .where((entry) => !entry.completedAt.toUtc().isBefore(threshold))
        .length;
  }

  static String _focusLabel(
    BuildContext context,
    List<SessionHistoryEntry> entries,
    DateTime now,
  ) {
    final threshold = now.toUtc().subtract(const Duration(hours: 24));
    final recent = entries
        .where((entry) => !entry.completedAt.toUtc().isBefore(threshold))
        .toList(growable: false);

    if (recent.isEmpty) {
      return '—';
    }

    final average =
        recent.map((entry) => entry.focusScore).reduce((a, b) => a + b) /
        recent.length;

    if (average >= 3.5) {
      return context.t(vi: 'Tốt', en: 'Good');
    }

    if (average >= 2.5) {
      return context.t(vi: 'Ổn', en: 'Okay');
    }

    return context.t(vi: 'Cần nghỉ', en: 'Need rest');
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _AiSystemPanel extends StatelessWidget {
  const _AiSystemPanel({required this.snapshot});

  final DiagnosisSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (snapshot == null) {
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
        child: Text(
          context.t(
            vi: 'Hoàn thành phiên đầu tiên để AI đánh giá.',
            en: 'Complete your first session for insights.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      );
    }

    final safeConfidence = snapshot!.confidenceScore.clamp(0.0, 1.0);
    final strength = _firstOrDash(snapshot!.strengths);
    final needReview = _firstOrDash(snapshot!.needsReview);
    final nextStep = snapshot!.nextSuggestedTopic.trim().isEmpty
        ? '—'
        : snapshot!.nextSuggestedTopic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: safeConfidence,
            backgroundColor: colors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
        ),
        const SizedBox(height: GrowMateLayout.contentGap),
        _InsightTile(
          icon: Icons.check_circle_rounded,
          iconColor: colors.tertiary,
          title: context.t(vi: 'Điểm tốt', en: 'Strengths'),
          subtitle: strength,
        ),
        const SizedBox(height: GrowMateLayout.space12),
        _InsightTile(
          icon: Icons.warning_amber_rounded,
          iconColor: colors.secondary,
          title: context.t(vi: 'Điểm cần cải thiện', en: 'Needs improvement'),
          subtitle: needReview,
        ),
        const SizedBox(height: GrowMateLayout.space12),
        _InsightTile(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: colors.primary,
          title: context.t(vi: 'Bước tiếp theo', en: 'Next step'),
          subtitle: nextStep,
        ),
      ],
    );
  }

  static String _firstOrDash(List<String> values) {
    if (values.isEmpty) {
      return '—';
    }

    final first = values.first.trim();
    return first.isEmpty ? '—' : first;
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

        // Hide card if no topics exist at all
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final title = dueItems.isEmpty
            ? context.t(vi: 'Ôn tập ngắt quãng', en: 'Spaced Review')
            : context.t(
                vi: 'Ôn tập ngắt quãng (${dueItems.length})',
                en: 'Spaced Review (${dueItems.length})',
              );

        final subtitle = dueItems.isEmpty
            ? context.t(
                vi: 'Không có chủ đề cần ôn hôm nay.',
                en: 'No topics to review today.',
              )
            : context.t(
                vi: 'Ưu tiên: ${dueItems.first.topic}',
                en: 'Priority: ${dueItems.first.topic}',
              );

        return _QuickStrip(
          icon: Icons.refresh_rounded,
          title: title,
          subtitle: subtitle,
          onTap: () {
            context.push(AppRoutes.spacedReview);
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
            ? context.t(
                vi: 'Gợi ý nghỉ thở 90 giây',
                en: 'Mindful Break suggestion (90s)',
              )
            : context.t(vi: 'Giữ nhịp ổn định', en: 'Keep steady rhythm');
        final subtitle = shouldSuggestBreak
            ? context.t(
                vi: 'Nghỉ nhẹ trước khi tiếp tục nhé.',
                en: 'Take a short break before continuing.',
              )
            : context.t(
                vi: 'Thấy mệt? Thử nghỉ thở 90 giây.',
                en: 'Tired? Try a 90-second breathing break.',
              );

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
            ? context.t(vi: 'Lịch thông minh', en: 'Smart Schedule')
            : context.t(
                vi: 'Mốc gần nhất: ${nearest.title}',
                en: 'Nearest milestone: ${nearest.title}',
              );

        final subtitle = nearest == null
            ? context.t(
                vi: 'Thêm lịch thi để AI ưu tiên ôn tập.',
                en: 'Add exams for AI prioritization.',
              )
            : _scheduleSubtitle(context, nearest, now);

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

  static String _scheduleSubtitle(
    BuildContext context,
    StudyScheduleItem item,
    DateTime now,
  ) {
    final daysLeft = item.dueAt.toLocal().difference(now).inDays;
    final label = item.type == 'exam'
        ? context.t(vi: 'bài thi', en: 'exam')
        : context.t(vi: 'hạn nộp', en: 'deadline');

    if (daysLeft <= 0) {
      return context.t(
        vi: 'Hôm nay: $label — ôn ${item.subject}.',
        en: 'Today: $label — review ${item.subject}.',
      );
    }

    return context.t(
      vi: 'Còn $daysLeft ngày — $label ${item.subject}.',
      en: '$daysLeft days — $label ${item.subject}.',
    );
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
            Icon(icon, size: 18, color: colors.primary),
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

class _ErrorStateWidget extends StatelessWidget {
  const _ErrorStateWidget({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 32, color: colors.error),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: 18, color: colors.error),
            label: Text(
              context.t(vi: 'Thử lại', en: 'Retry'),
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: GrowMateLayout.space12),
          Text(
            context.t(vi: 'Đang tải dữ liệu...', en: 'Loading data...'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MentalStateChip extends StatelessWidget {
  const _MentalStateChip({required this.focusScore});

  final double focusScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final String emoji;
    final String label;

    if (focusScore >= 3.5) {
      emoji = '🟢';
      label = context.t(vi: 'Tập trung', en: 'Focused');
    } else if (focusScore >= 2.5) {
      emoji = '🟡';
      label = context.t(vi: 'Hơi mệt', en: 'Slightly tired');
    } else {
      emoji = '🔴';
      label = context.t(vi: 'Cần nghỉ', en: 'Needs rest');
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.tertiary.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 22,
      color: colors.primaryContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, size: 22, color: colors.primary),
              const SizedBox(width: GrowMateLayout.space8),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Chào mừng bạn đến GrowMate! 🌱',
                    en: 'Welcome to GrowMate! 🌱',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space12),
          _OnboardingStep(
            number: '①',
            text: context.t(
              vi: 'Làm quiz Đạo hàm cơ bản để AI hiểu lỗ hổng kiến thức',
              en: 'Take a Derivatives quiz so AI understands your knowledge gaps',
            ),
          ),
          const SizedBox(height: 6),
          _OnboardingStep(
            number: '②',
            text: context.t(
              vi: 'Nhận chẩn đoán cá nhân hóa từ AI',
              en: 'Receive a personalized AI diagnosis',
            ),
          ),
          const SizedBox(height: 6),
          _OnboardingStep(
            number: '③',
            text: context.t(
              vi: 'Theo lộ trình AI gợi ý để tiến bộ',
              en: 'Follow the AI-suggested roadmap to improve',
            ),
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(vi: 'Mình hiểu rồi', en: 'Got it'),
            variant: ZenButtonVariant.secondary,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
