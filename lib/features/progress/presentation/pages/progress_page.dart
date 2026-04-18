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
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_error_card.dart';
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
  bool _historySyncedFromServer = false;

  bool get _shouldWaitForRealMastery =>
      widget.realProgressRepository != null && _resolveSessionId() != null;

  @override
  void initState() {
    super.initState();
    _historyStream = widget.sessionHistoryRepository
        .watchHistory()
        .asBroadcastStream();
    _realMasteryFuture = _loadRealMastery();
    unawaited(_syncSessionHistoryFromServer());
  }

  void refresh() {
    setState(() {
      _streamKey = UniqueKey();
      _historyStream = widget.sessionHistoryRepository
          .watchHistory()
          .asBroadcastStream();
      _realMasteryFuture = _loadRealMastery();
    });
    unawaited(_syncSessionHistoryFromServer());
  }

  Future<void> _syncSessionHistoryFromServer() async {
    final quizApiRepository = widget.quizApiRepository;
    if (quizApiRepository == null) {
      if (mounted) {
        setState(() {
          _historySyncedFromServer = false;
        });
      }
      return;
    }

    try {
      final response = await quizApiRepository.getQuizHistory(
        limit: 50,
        offset: 0,
      );

      for (final item in response.items) {
        final sessionId = item.sessionId.trim();
        if (sessionId.isEmpty) {
          continue;
        }

        final confidence = (item.summary.accuracyPercent / 100)
            .clamp(0.0, 1.0)
            .toDouble();
        await widget.sessionHistoryRepository.upsertCompletedSession(
          sourceKey: 'session:$sessionId',
          topic: _historyTopicLabel(sessionId),
          mode: item.status.toLowerCase() == 'abandoned'
              ? 'recovery'
              : 'academic',
          durationMinutes: _historyDurationMinutes(item.summary.answeredCount),
          focusScore: (confidence * 4).clamp(0.0, 4.0).toDouble(),
          confidenceScore: confidence,
          nextAction: _historyNextAction(confidence),
          completedAt: item.endTime ?? item.startTime ?? DateTime.now().toUtc(),
        );
      }

      if (mounted) {
        setState(() {
          _historySyncedFromServer = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _historySyncedFromServer = false;
        });
      }
      debugPrint('⚠️ Unable to sync quiz history from backend: $error');
    }
  }

  static String _historyTopicLabel(String sessionId) {
    final suffix = sessionId.length > 8
        ? sessionId.substring(sessionId.length - 8)
        : sessionId;
    return 'Phiên quiz #$suffix';
  }

  static int _historyDurationMinutes(int answeredCount) {
    final estimated = answeredCount <= 0 ? 8 : answeredCount * 2;
    return estimated.clamp(5, 120).toInt();
  }

  static String _historyNextAction(double confidence) {
    if (confidence >= 0.85) {
      return 'Tăng nhẹ độ khó ở phiên kế tiếp';
    }
    if (confidence >= 0.6) {
      return 'Ôn lại nhóm câu sai và làm thêm 2 câu tương tự';
    }
    return 'Ôn lại lý thuyết cốt lõi trước khi tiếp tục';
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
    if (widget.realProgressRepository == null) {
      return MockUserProgressGenerator.fromUserProfile(
        widget.profile,
        forceEmptyState: widget.forceEmptyState,
      );
    }

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
                                  onRetry: refresh,
                                );
                              }

                              final progress = _mergeProgressWithBeliefs(
                                baseProgress,
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
                                    _RecentSessionsSection(
                                      history: history,
                                      fromServer: _historySyncedFromServer,
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
        child: Text(
          context.t(
            vi: 'Chưa có phiên nào để hiển thị.',
            en: 'No sessions to show yet.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
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
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.surfaceContainerHigh),
                ),
                child: Row(
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
