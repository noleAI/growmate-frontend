import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../features/session/data/models/session_history_entry.dart';
import '../../../../features/session/data/repositories/session_history_repository.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
import '../../../../shared/widgets/zen_empty_state.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/zen_screen_header.dart';
import '../../../../shared/widgets/shimmer/shimmer_text.dart';
import '../../../../shared/widgets/ai_reflection_widget.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_cubit.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_state.dart';
import '../../../quiz/data/repositories/quiz_api_repository.dart';
import '../../data/mock_user_progress_generator.dart';
import '../../data/real_progress_repository.dart';
import '../widgets/ai_progress_narrative.dart';
import '../widgets/formula_handbook_tab.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    SessionHistoryRepository? sessionHistoryRepository,
    RealProgressRepository? realProgressRepository,
    QuizApiRepository? quizApiRepository,
  }) : _profile = null,
       _forceEmptyState = false,
       _sessionHistoryRepository = sessionHistoryRepository,
       _realProgressRepository = realProgressRepository,
       _quizApiRepository = quizApiRepository;

  final UserProfile? _profile;
  final bool _forceEmptyState;
  final SessionHistoryRepository? _sessionHistoryRepository;
  final RealProgressRepository? _realProgressRepository;
  final QuizApiRepository? _quizApiRepository;

  @override
  Widget build(BuildContext context) {
    return ProgressScreen(
      profile: _profile,
      forceEmptyState: _forceEmptyState,
      sessionHistoryRepository:
          _sessionHistoryRepository ?? SessionHistoryRepository.instance,
      realProgressRepository: _realProgressRepository,
      quizApiRepository: _quizApiRepository,
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.profile,
    this.forceEmptyState = false,
    required this.sessionHistoryRepository,
    this.realProgressRepository,
    this.quizApiRepository,
  });

  final UserProfile? profile;
  final bool forceEmptyState;
  final SessionHistoryRepository sessionHistoryRepository;
  final RealProgressRepository? realProgressRepository;
  final QuizApiRepository? quizApiRepository;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Key để force rebuild khi user tap retry
  UniqueKey _streamKey = UniqueKey();
  late Stream<List<SessionHistoryEntry>> _historyStream;
  Future<List<TopicMastery>>? _realMasteryFuture;
  bool _isRefreshingProgress = false;

  bool get _shouldWaitForRealMastery =>
      widget.realProgressRepository != null && _resolveSessionId() != null;

  @override
  void initState() {
    super.initState();
    _historyStream = widget.sessionHistoryRepository
        .watchHistory()
        .asBroadcastStream();
    _realMasteryFuture = _loadRealMastery();
  }

  Future<void> _refreshProgress() async {
    if (_isRefreshingProgress) {
      return;
    }

    setState(() {
      _isRefreshingProgress = true;
      _streamKey = UniqueKey();
      _historyStream = widget.sessionHistoryRepository
          .watchHistory()
          .asBroadcastStream();
      _realMasteryFuture = _loadRealMastery();
    });

    try {
      await Future.wait<Object?>([
        _historyStream.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => const <SessionHistoryEntry>[],
        ),
        (_realMasteryFuture ?? Future.value(const <TopicMastery>[])).timeout(
          const Duration(seconds: 2),
          onTimeout: () => const <TopicMastery>[],
        ),
      ]);
    } catch (_) {
      // Keep the refresh affordance resilient even when one source times out.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingProgress = false;
        });
      }
    }
  }

  Future<List<TopicMastery>> _loadRealMastery() async {
    final sessionId = _resolveSessionId();
    final repo = widget.realProgressRepository;

    if (sessionId == null || repo == null) {
      return const <TopicMastery>[];
    }

    return repo.fetchMasteryMap(sessionId: sessionId);
  }

  String? _resolveSessionId() {
    try {
      final cubit = context.read<AgenticSessionCubit>();
      return cubit.state.sessionId;
    } catch (_) {
      return null;
    }
  }

  UserProgressSnapshot _mergeProgressWithBeliefs(
    UserProgressSnapshot base,
    List<TopicMastery> realMastery,
  ) {
    if (realMastery.isEmpty) {
      return base;
    }

    final fixedConcepts = realMastery
        .where((item) => item.score >= 3.0)
        .take(3)
        .map((item) => item.topic)
        .toList(growable: false);

    return UserProgressSnapshot(
      learningRhythm: base.learningRhythm,
      weeklyConsistency: base.weeklyConsistency,
      fixedConcepts: fixedConcepts,
      masteryMap: realMastery,
      moodTrend: base.moodTrend,
    );
  }

  UserProgressSnapshot _buildBaseProgressSnapshot(
    List<SessionHistoryEntry> history,
  ) {
    return _buildRealProgressFromHistory(history);
  }

  UserProgressSnapshot _buildRealProgressFromHistory(
    List<SessionHistoryEntry> history,
  ) {
    if (widget.forceEmptyState || history.isEmpty) {
      return const UserProgressSnapshot(
        learningRhythm: '',
        weeklyConsistency: '',
        fixedConcepts: <String>[],
        masteryMap: <TopicMastery>[],
        moodTrend: <MoodTrendPoint>[],
      );
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = history
        .where((entry) => entry.completedAt.toLocal().isAfter(weekAgo))
        .toList(growable: false);
    final baseline = recent.isEmpty ? history : recent;

    final uniqueStudyDays = baseline
        .map(
          (entry) => DateTime(
            entry.completedAt.toLocal().year,
            entry.completedAt.toLocal().month,
            entry.completedAt.toLocal().day,
          ).toIso8601String(),
        )
        .toSet()
        .length;

    final avgDuration =
        baseline.fold<int>(0, (sum, entry) => sum + entry.durationMinutes) /
        baseline.length;

    final topicFrequency = <String, int>{};
    for (final entry in baseline) {
      final topic = entry.topic.trim();
      if (topic.isEmpty) {
        continue;
      }
      topicFrequency[topic] = (topicFrequency[topic] ?? 0) + 1;
    }

    final fixedConcepts = topicFrequency.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedByTime = List<SessionHistoryEntry>.from(baseline)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final trendSource = sortedByTime.length > 4
        ? sortedByTime.sublist(sortedByTime.length - 4)
        : sortedByTime;

    final moodTrend = trendSource
        .asMap()
        .entries
        .map(
          (entry) => MoodTrendPoint(
            sessionLabel: 'Phiên ${entry.key + 1}',
            focusScore: entry.value.focusScore.clamp(0.0, 4.0).toDouble(),
          ),
        )
        .toList(growable: false);

    return UserProgressSnapshot(
      learningRhythm:
          'Trung bình ${avgDuration.round()} phút mỗi phiên trong dữ liệu gần đây.',
      weeklyConsistency:
          '$uniqueStudyDays/7 ngày có hoạt động học tập tuần này',
      fixedConcepts: fixedConcepts
          .take(3)
          .map((e) => e.key)
          .toList(growable: false),
      masteryMap: const <TopicMastery>[],
      moodTrend: moodTrend,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactPhone = screenWidth < 420;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ZenPageContainer(
          includeBottomSafeArea: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZenScreenHeader(
                eyebrow: context.t(
                  vi: 'Theo dõi nhịp học',
                  en: 'Track your study pulse',
                ),
                title: context.t(
                  vi: 'Tiến trình tuần này',
                  en: 'This week\'s progress',
                ),
                subtitle: context.t(
                  vi: 'Theo dõi nhịp học, phiên gần đây và công thức trọng tâm để ôn tập đúng lúc.',
                  en: 'Track learning rhythm, recent sessions, and key formulas for timely revision.',
                ),
                icon: Icons.insights_rounded,
                chips: [
                  ZenHeaderChipData(
                    label: widget.realProgressRepository != null
                        ? context.t(
                            vi: 'Dữ liệu từ server',
                            en: 'Server-backed data',
                          )
                        : context.t(
                            vi: 'Có local fallback',
                            en: 'Local fallback ready',
                          ),
                    icon: widget.realProgressRepository != null
                        ? Icons.cloud_done_rounded
                        : Icons.offline_bolt_rounded,
                  ),
                  ZenHeaderChipData(
                    label: context.t(
                      vi: 'Sổ tay công thức',
                      en: 'Formula handbook',
                    ),
                    icon: Icons.auto_stories_rounded,
                  ),
                ],
              ),
              const SizedBox(height: GrowMateLayout.space12),
              const SizedBox(height: GrowMateLayout.sectionGap),
              _ProgressTabHeader(
                isCompact: isCompactPhone,
                isRefreshing: _isRefreshingProgress,
                onRefresh: () => unawaited(_refreshProgress()),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 0: Progress content
                    KeyedSubtree(
                      key: _streamKey,
                      child: StreamBuilder<List<SessionHistoryEntry>>(
                        stream: _historyStream,
                        initialData: const <SessionHistoryEntry>[],
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return ZenErrorCard(
                              message: context.t(
                                vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
                                en: 'Unable to load data. Please try again.',
                              ),
                              onRetry: () => unawaited(_refreshProgress()),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const _LoadingStateWidget();
                          }

                          final history =
                              snapshot.data ?? const <SessionHistoryEntry>[];
                          final baseProgress = _buildBaseProgressSnapshot(
                            history,
                          );

                          return FutureBuilder<List<TopicMastery>>(
                            future: _realMasteryFuture,
                            builder: (context, masterySnapshot) {
                              if (_shouldWaitForRealMastery &&
                                  masterySnapshot.connectionState !=
                                      ConnectionState.done &&
                                  !masterySnapshot.hasData) {
                                return const _LoadingStateWidget();
                              }

                              if (_shouldWaitForRealMastery &&
                                  masterySnapshot.hasError &&
                                  baseProgress.isEmpty) {
                                return ZenErrorCard(
                                  message: context.t(
                                    vi: 'Không tải được dữ liệu tiến trình từ server.',
                                    en: 'Unable to load progress data from server.',
                                  ),
                                  onRetry: () => unawaited(_refreshProgress()),
                                );
                              }

                              final progress = _mergeProgressWithBeliefs(
                                baseProgress,
                                masterySnapshot.data ?? const <TopicMastery>[],
                              );

                              return RefreshIndicator(
                                onRefresh: _refreshProgress,
                                child: ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    isCompactPhone
                                        ? GrowMateLayout.space16
                                        : GrowMateLayout.sectionGapLg,
                                    0,
                                    GrowMateLayout.sectionGap,
                                  ),
                                  children: [
                                    _ProgressSnapshotStrip(
                                      progress: progress,
                                      sessionCount: history.length,
                                      history: history,
                                    ),
                                    const SizedBox(
                                      height: GrowMateLayout.sectionGap,
                                    ),
                                    AiProgressNarrative(
                                      progress: progress,
                                      isConfirmed:
                                          widget.realProgressRepository != null,
                                    ),
                                    // Agentic reflection summary
                                    BlocBuilder<
                                      AgenticSessionCubit,
                                      AgenticSessionState
                                    >(
                                      buildWhen: (prev, curr) =>
                                          prev.latestReflection !=
                                          curr.latestReflection,
                                      builder: (context, agenticState) {
                                        if (agenticState.latestReflection ==
                                            null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: GrowMateLayout.space16,
                                          ),
                                          child: AiReflectionWidget(
                                            reflection:
                                                agenticState.latestReflection!,
                                            stepNumber: agenticState.stepCount,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(
                                      height: GrowMateLayout.sectionGap,
                                    ),
                                    // Đã loại bỏ các section: Ôn tập ngắt quãng, Huy hiệu thành tựu, Lịch học thông minh, Timeline phiên học
                                    _WeeklyMomentumSection(
                                      history: history,
                                      progress: progress,
                                    ),
                                    const SizedBox(
                                      height: GrowMateLayout.sectionGap,
                                    ),
                                    _RecentSessionsSection(
                                      history: history,
                                      fromServer: widget
                                          .sessionHistoryRepository
                                          .hasRemoteSourceConfigured,
                                    ),
                                    const SizedBox(
                                      height: GrowMateLayout.sectionGap,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ), // KeyedSubtree
                    // Tab 1: Formula handbook
                    const FormulaHandbookTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: GrowMateBottomNavBar(
          currentTab: GrowMateTab.progress,
          onTabSelected: (tab) => handleTabNavigation(context, tab),
        ),
      ),
    ); // DefaultTabController
  }
}

class _WeeklyMomentumSection extends StatelessWidget {
  const _WeeklyMomentumSection({required this.history, required this.progress});

  final List<SessionHistoryEntry> history;
  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final now = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (index) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index)),
    );

    final sessionsByDay = <String, int>{};
    var focusSum = 0.0;
    var focusCount = 0;

    for (final entry in history) {
      final dayKey = _dateKey(entry.completedAt.toLocal());
      sessionsByDay[dayKey] = (sessionsByDay[dayKey] ?? 0) + 1;

      if (entry.completedAt.isAfter(now.subtract(const Duration(days: 7)))) {
        focusSum += entry.focusScore;
        focusCount += 1;
      }
    }

    final avgFocus = focusCount == 0 ? 0.0 : focusSum / focusCount;
    final weakestTopic = _resolveWeakestTopic(context, progress);
    final tomorrowAction = history.isEmpty
        ? context.t(
            vi: 'Bắt đầu 1 phiên 10 phút để lấy lại nhịp.',
            en: 'Start one 10-min session to regain rhythm.',
          )
        : context.t(
            vi: 'Ôn $weakestTopic 12 phút, rồi 2 câu tự kiểm tra.',
            en: '$weakestTopic for 12 min, then 2 self-check Qs.',
          );

    return Section(
      title: context.t(
        vi: 'Kế hoạch tuần & ngày mai',
        en: 'Weekly plan & tomorrow',
      ),
      subtitle: context.t(
        vi: 'Biểu đồ và gợi ý phiên kế tiếp',
        en: 'Chart and next session suggestions',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer.withValues(alpha: 0.45),
                  colors.surfaceContainerLow,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniMetricChip(
                      label: context.t(
                        vi: 'Focus TB ${avgFocus.toStringAsFixed(1)}/4',
                        en: 'Focus avg ${avgFocus.toStringAsFixed(1)}/4',
                      ),
                    ),
                    _MiniMetricChip(
                      label: context.t(
                        vi: 'Chủ đề ưu tiên $weakestTopic',
                        en: 'Priority topic $weakestTopic',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: isCompact ? 144 : 170,
                  child: BarChart(
                    BarChartData(
                      maxY: 4,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= days.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _weekdayShort(context, days[index]),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: days
                          .asMap()
                          .entries
                          .map((entry) {
                            final dayKey = _dateKey(entry.value);
                            final count = (sessionsByDay[dayKey] ?? 0).clamp(
                              0,
                              4,
                            );

                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: count.toDouble(),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(8),
                                  color: colors.primary,
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 4,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(
                    vi: 'TB tập trung 7 ngày: ${avgFocus.toStringAsFixed(1)}/4',
                    en: '7-day focus avg: ${avgFocus.toStringAsFixed(1)}/4',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t(
                          vi: 'Hành động ngày mai: $tomorrowAction',
                          en: 'Tomorrow action: $tomorrowAction',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTabHeader extends StatelessWidget {
  const _ProgressTabHeader({
    required this.isCompact,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isCompact;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget refreshButton() {
      return Tooltip(
        message: context.t(
          vi: 'Tải lại dữ liệu tiến trình',
          en: 'Refresh progress data',
        ),
        child: Material(
          color: theme.colorScheme.surface,
          shape: isCompact
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
              : const CircleBorder(),
          child: isCompact
              ? InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isRefreshing ? null : onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRefreshing)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.1,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          context.t(vi: 'Làm mới', en: 'Refresh'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHigh,
                    disabledForegroundColor:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                  icon: isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
        ),
      );
    }

    final tabs = Container(
      margin: EdgeInsets.only(left: 4, right: isCompact ? 4 : 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insights_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.t(vi: 'Tiến trình', en: 'Progress'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.t(vi: 'Sổ tay', en: 'Handbook'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tabs,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: refreshButton()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: tabs), refreshButton()],
    );
  }
}

class _ProgressSnapshotStrip extends StatelessWidget {
  const _ProgressSnapshotStrip({
    required this.progress,
    required this.sessionCount,
    required this.history,
  });

  final UserProgressSnapshot progress;
  final int sessionCount;
  final List<SessionHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final primaryTopic = progress.masteryMap.isNotEmpty
        ? _topicLabel(
            context,
            (List<TopicMastery>.from(progress.masteryMap)
                  ..sort((a, b) => a.score.compareTo(b.score)))
                .first
                .topic,
          )
        : history.isNotEmpty
        ? history.first.topic
        : context.t(vi: 'Đợi cập nhật', en: 'Awaiting update');

    final items = <({IconData icon, String label, String value, Color accent})>[
      (
        icon: Icons.calendar_view_week_rounded,
        label: context.t(vi: 'Nhịp tuần', en: 'Weekly rhythm'),
        value: progress.weeklyConsistency.isEmpty
            ? context.t(vi: 'Chưa có dữ liệu', en: 'No data yet')
            : progress.weeklyConsistency,
        accent: colors.primary,
      ),
      (
        icon: Icons.history_rounded,
        label: context.t(vi: 'Phiên gần đây', en: 'Recent sessions'),
        value: context.t(
          vi: '$sessionCount phiên',
          en: '$sessionCount sessions',
        ),
        accent: colors.tertiary,
      ),
      (
        icon: Icons.flag_circle_rounded,
        label: context.t(vi: 'Ưu tiên tiếp theo', en: 'Next priority'),
        value: primaryTopic,
        accent: colors.secondary,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withValues(alpha: 0.92),
            colors.primaryContainer.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => SizedBox(
                width: isCompact
                    ? double.infinity
                    : ((MediaQuery.sizeOf(context).width - 64) / 3),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
        progress.masteryMap
            .where((topic) => topic.score < 3.0)
            .toList(growable: false)
          ..sort((a, b) => a.score.compareTo(b.score));

    if (gaps.isEmpty) {
      return context.t(vi: 'một chủ đề nâng cao', en: 'an advanced topic');
    }

    return _topicLabel(context, gaps.first.topic);
  }
}

class _MiniMetricChip extends StatelessWidget {
  const _MiniMetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({
    required this.history,
    required this.fromServer,
  });

  final List<SessionHistoryEntry> history;
  final bool fromServer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (history.isEmpty) {
      return Section(
        title: context.t(vi: 'Phiên gần đây', en: 'Recent sessions'),
        subtitle: context.t(
          vi: 'Lịch sử phiên học theo session_id',
          en: 'Session history keyed by session_id',
        ),
        child: ZenEmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: context.t(
            vi: 'Bạn chưa có phiên học nào gần đây',
            en: 'No recent sessions yet',
          ),
          subtitle: context.t(
            vi: 'Bắt đầu một phiên quiz ngắn để hệ thống ghi nhận tiến trình và tạo gợi ý cá nhân hóa.',
            en: 'Start a short quiz session so the system can track progress and generate personalized suggestions.',
          ),
          primaryLabel: context.t(vi: 'Làm quiz ngay', en: 'Start a quiz'),
          onPrimaryPressed: () => context.push(AppRoutes.quiz),
          centered: false,
        ),
      );
    }

    final latest = history.take(5).toList(growable: false);
    final sourceLabel = fromServer
        ? context.t(vi: 'Nguồn: Server history', en: 'Source: Server history')
        : context.t(vi: 'Nguồn: Local fallback', en: 'Source: Local fallback');

    return Section(
      title: context.t(vi: 'Phiên gần đây', en: 'Recent sessions'),
      subtitle: context.t(
        vi: 'Mở nhanh chi tiết kết quả theo session',
        en: 'Open result details by session',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fromServer
                  ? colors.primaryContainer.withValues(alpha: 0.45)
                  : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              sourceLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...latest.map((entry) {
            final sessionId = _extractSessionId(entry.sourceKey);
            final statusLabel = entry.mode.toLowerCase() == 'recovery'
                ? context.t(vi: 'Phục hồi', en: 'Recovery')
                : context.t(vi: 'Học tập', en: 'Academic');
            final dateLabel = _formatLocalDateTime(entry.completedAt.toLocal());

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.surfaceContainerLow,
                      colors.surfaceContainerHigh.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.topic,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MiniMetricChip(label: statusLabel),
                              _MiniMetricChip(
                                label: context.t(
                                  vi: 'Focus ${entry.focusScore.toStringAsFixed(1)}/4',
                                  en: 'Focus ${entry.focusScore.toStringAsFixed(1)}/4',
                                ),
                              ),
                              _MiniMetricChip(label: dateLabel),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: sessionId == null
                                  ? null
                                  : () {
                                      final location = Uri(
                                        path: AppRoutes.diagnosis,
                                        queryParameters: <String, String>{
                                          'submissionId': sessionId,
                                        },
                                      ).toString();
                                      context.push(location);
                                    },
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text(context.t(vi: 'Xem phiên', en: 'Open')),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.topic,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.t(
                                    vi: '$statusLabel • Focus ${entry.focusScore.toStringAsFixed(1)}/4 • $dateLabel',
                                    en: '$statusLabel • Focus ${entry.focusScore.toStringAsFixed(1)}/4 • $dateLabel',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: sessionId == null
                                ? null
                                : () {
                                    final location = Uri(
                                      path: AppRoutes.diagnosis,
                                      queryParameters: <String, String>{
                                        'submissionId': sessionId,
                                      },
                                    ).toString();
                                    context.push(location);
                                  },
                            child: Text(context.t(vi: 'Xem', en: 'Open')),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

String? _extractSessionId(String sourceKey) {
  final trimmed = sourceKey.trim();
  if (trimmed.startsWith('session:')) {
    final value = trimmed.substring('session:'.length).trim();
    return value.isEmpty ? null : value;
  }
  if (trimmed.startsWith('submission:')) {
    final segments = trimmed.split('|');
    if (segments.isEmpty) {
      return null;
    }
    final value = segments.first.substring('submission:'.length).trim();
    return value.isEmpty ? null : value;
  }
  return null;
}

String _formatLocalDateTime(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date • $time';
}

String _topicLabel(BuildContext context, String topic) {
  if (!context.isEnglish) {
    return topic;
  }

  switch (topic.trim()) {
    case 'Đạo hàm':
      return 'Derivatives';
    case 'Giới hạn':
      return 'Limits';
    case 'Tích phân':
      return 'Integrals';
    case 'Hàm hợp':
      return 'Composite functions';
    case 'Ứng dụng':
      return 'Applications';
    case 'Đạo hàm đa thức':
      return 'Polynomial derivatives';
    case 'Quy tắc tích':
      return 'Product rule';
    case 'Giới hạn cơ bản':
      return 'Basic limits';
    default:
      return topic;
  }
}

String _dateKey(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _weekdayShort(BuildContext context, DateTime value) {
  if (context.isEnglish) {
    switch (value.weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  switch (value.weekday) {
    case DateTime.monday:
      return 'T2';
    case DateTime.tuesday:
      return 'T3';
    case DateTime.wednesday:
      return 'T4';
    case DateTime.thursday:
      return 'T5';
    case DateTime.friday:
      return 'T6';
    case DateTime.saturday:
      return 'T7';
    default:
      return 'CN';
  }
}

class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget skeletonCard({
      required double height,
      EdgeInsetsGeometry padding = const EdgeInsets.all(
        GrowMateLayout.contentGap,
      ),
      required List<Widget> children,
    }) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: GrowMateLayout.sectionGapLg),
      children: [
        skeletonCard(
          height: 170,
          children: const [
            ShimmerText(width: 150, height: 14),
            SizedBox(height: 18),
            ShimmerText(width: 260, height: 30),
            SizedBox(height: 14),
            ShimmerText(width: double.infinity, height: 12),
            SizedBox(height: 10),
            ShimmerText(width: 210, height: 12),
            Spacer(),
            ShimmerText(width: 120, height: 12),
          ],
        ),
        const SizedBox(height: GrowMateLayout.sectionGap),
        skeletonCard(
          height: 220,
          children: const [
            ShimmerText(width: 170, height: 14),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ShimmerText(width: double.infinity, height: 84),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: ShimmerText(width: double.infinity, height: 84),
                ),
              ],
            ),
            SizedBox(height: 18),
            ShimmerText(width: double.infinity, height: 12),
            SizedBox(height: 10),
            ShimmerText(width: 220, height: 12),
          ],
        ),
        const SizedBox(height: GrowMateLayout.sectionGap),
        skeletonCard(
          height: 200,
          children: const [
            ShimmerText(width: 190, height: 14),
            SizedBox(height: 18),
            ShimmerText(width: double.infinity, height: 48),
            SizedBox(height: 12),
            ShimmerText(width: double.infinity, height: 48),
            SizedBox(height: 12),
            ShimmerText(width: double.infinity, height: 48),
          ],
        ),
      ],
    );
  }
}
