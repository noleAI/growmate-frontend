import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/layout.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../features/session/data/models/session_history_entry.dart';
import '../../../../features/session/data/repositories/session_history_repository.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/shimmer/shimmer_text.dart';
import '../../../../shared/widgets/ai_reflection_widget.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_cubit.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_state.dart';
import '../../data/mock_user_progress_generator.dart';
import '../../data/real_progress_repository.dart';
import '../widgets/ai_progress_narrative.dart';
import '../widgets/formula_handbook_tab.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    SessionHistoryRepository? sessionHistoryRepository,
    RealProgressRepository? realProgressRepository,
  }) : _profile = null,
       _forceEmptyState = false,
       _sessionHistoryRepository = sessionHistoryRepository,
       _realProgressRepository = realProgressRepository;

  final UserProfile? _profile;
  final bool _forceEmptyState;
  final SessionHistoryRepository? _sessionHistoryRepository;
  final RealProgressRepository? _realProgressRepository;

  @override
  Widget build(BuildContext context) {
    return ProgressScreen(
      profile: _profile,
      forceEmptyState: _forceEmptyState,
      sessionHistoryRepository:
          _sessionHistoryRepository ?? SessionHistoryRepository.instance,
      realProgressRepository: _realProgressRepository,
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
  });

  final UserProfile? profile;
  final bool forceEmptyState;
  final SessionHistoryRepository sessionHistoryRepository;
  final RealProgressRepository? realProgressRepository;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Key để force rebuild khi user tap retry
  UniqueKey _streamKey = UniqueKey();
  late Stream<List<SessionHistoryEntry>> _historyStream;
  Future<List<TopicMastery>>? _realMasteryFuture;

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

  void refresh() {
    setState(() {
      _streamKey = UniqueKey();
      _historyStream = widget.sessionHistoryRepository
          .watchHistory()
          .asBroadcastStream();
      _realMasteryFuture = _loadRealMastery();
    });
  }

  Future<List<TopicMastery>> _loadRealMastery() async {
    final sessionId = _resolveSessionId();
    final repo = widget.realProgressRepository;

    if (sessionId == null || repo == null) {
      return const <TopicMastery>[];
    }

    try {
      return await repo.fetchMasteryMap(sessionId: sessionId);
    } catch (_) {
      return const <TopicMastery>[];
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mockProgress = MockUserProgressGenerator.fromUserProfile(
      widget.profile,
      forceEmptyState: widget.forceEmptyState,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ZenPageContainer(
          includeBottomSafeArea: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t(
                        vi: 'Tiến trình tuần này',
                        en: 'This week\'s progress',
                      ),
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  // Đã xóa icon Bảng xếp hạng
                ],
              ),
              const SizedBox(height: GrowMateLayout.sectionGap),
              TabBar(
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    text: context.t(vi: '📊 Tiến trình', en: '📊 Progress'),
                  ),
                  Tab(
                    text: context.t(vi: '📖 Sổ tay', en: '📖 Handbook'),
                  ),
                ],
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
                              onRetry: () {
                                context
                                    .findAncestorStateOfType<
                                      _ProgressScreenState
                                    >()
                                    ?.refresh();
                              },
                            );
                          }

                          if (!snapshot.hasData) {
                            return const _LoadingStateWidget();
                          }

                          final history =
                              snapshot.data ?? const <SessionHistoryEntry>[];

                          return FutureBuilder<List<TopicMastery>>(
                            future: _realMasteryFuture,
                            builder: (context, masterySnapshot) {
                              if (_shouldWaitForRealMastery &&
                                  masterySnapshot.connectionState !=
                                      ConnectionState.done &&
                                  !masterySnapshot.hasData) {
                                return const _LoadingStateWidget();
                              }

                              final progress = _mergeProgressWithBeliefs(
                                mockProgress,
                                masterySnapshot.data ?? const <TopicMastery>[],
                              );

                              return RefreshIndicator(
                                onRefresh: () async {
                                  refresh();
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );
                                },
                                child: ListView(
                                  children: [
                                    const SizedBox(
                                      height: GrowMateLayout.sectionGapLg,
                                    ),
                                    AiProgressNarrative(progress: progress),
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
                                      height: GrowMateLayout.sectionGapLg,
                                    ),
                                    // Đã loại bỏ các section: Ôn tập ngắt quãng, Huy hiệu thành tựu, Lịch học thông minh, Timeline phiên học
                                    _WeeklyMomentumSection(
                                      history: history,
                                      progress: progress,
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
          SizedBox(
            height: 190,
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
                      final count = (sessionsByDay[dayKey] ?? 0).clamp(0, 4);

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
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'TB tập trung 7 ngày: ${avgFocus.toStringAsFixed(1)}/4',
              en: '7-day focus avg: ${avgFocus.toStringAsFixed(1)}/4',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.t(
                vi: 'Hành động ngày mai: $tomorrowAction',
                en: 'Tomorrow action: $tomorrowAction',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveWeakestTopic(
    BuildContext context,
    UserProgressSnapshot progress,
  ) {
    final gaps =
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerText(width: 180, height: 14),
          SizedBox(height: 10),
          ShimmerText(width: double.infinity, height: 10),
          SizedBox(height: 8),
          ShimmerText(width: 140, height: 10),
        ],
      ),
    );
  }
}
