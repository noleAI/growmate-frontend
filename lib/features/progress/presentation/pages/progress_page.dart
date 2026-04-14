import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../features/achievement/data/models/achievement_badge.dart';
import '../../../../features/achievement/data/repositories/achievement_repository.dart';
import '../../../../features/achievement/presentation/achievement_i18n.dart';
import '../../../../features/review/data/models/spaced_review_item.dart';
import '../../../../features/review/data/repositories/spaced_repetition_repository.dart';
import '../../../../features/schedule/data/models/study_schedule_item.dart';
import '../../../../features/schedule/data/repositories/study_schedule_repository.dart';
import '../../../../features/session/data/models/session_history_entry.dart';
import '../../../../features/session/data/repositories/session_history_repository.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../data/mock_user_progress_generator.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({
    super.key,
    SessionHistoryRepository? sessionHistoryRepository,
  }) : _profile = null,
       _forceEmptyState = false,
       _sessionHistoryRepository = sessionHistoryRepository;

  final UserProfile? _profile;
  final bool _forceEmptyState;
  final SessionHistoryRepository? _sessionHistoryRepository;

  @override
  Widget build(BuildContext context) {
    return ProgressScreen(
      profile: _profile,
      forceEmptyState: _forceEmptyState,
      sessionHistoryRepository:
          _sessionHistoryRepository ?? SessionHistoryRepository.instance,
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.profile,
    this.forceEmptyState = false,
    required this.sessionHistoryRepository,
  });

  final UserProfile? profile;
  final bool forceEmptyState;
  final SessionHistoryRepository sessionHistoryRepository;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Key để force rebuild khi user tap retry
  UniqueKey _streamKey = UniqueKey();

  void refresh() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress = MockUserProgressGenerator.fromUserProfile(
      widget.profile,
      forceEmptyState: widget.forceEmptyState,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        includeBottomSafeArea: false,
        child: KeyedSubtree(
          key: _streamKey,
          child: StreamBuilder<List<SessionHistoryEntry>>(
            stream: widget.sessionHistoryRepository.watchHistory(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorStateWidget(
                  message: context.t(
                    vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
                    en: 'Unable to load data. Please try again.',
                  ),
                  onRetry: () {
                    context
                        .findAncestorStateOfType<_ProgressScreenState>()
                        ?.refresh();
                  },
                );
              }

              if (!snapshot.hasData) {
                return const _LoadingStateWidget();
              }

              final history = snapshot.data ?? const <SessionHistoryEntry>[];

              return ListView(
                children: [
                  const GrowMateTopAppBar(avatarNotificationOnly: true),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  Text(
                    context.t(
                      vi: 'Tiến trình tuần này',
                      en: 'This week\'s progress',
                    ),
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: GrowMateLayout.space8),
                  Text(
                    context.t(
                      vi: 'Tập trung vào chủ đề quan trọng nhất.',
                      en: 'Focus on the most important topic.',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  if (progress.isEmpty)
                    const _ProgressEmptyState()
                  else ...[
                    _SummarySection(progress: progress),
                    const SizedBox(height: GrowMateLayout.sectionGapLg),
                    _StrengthSection(progress: progress),
                    const SizedBox(height: GrowMateLayout.sectionGapLg),
                    _WeaknessSection(progress: progress),
                  ],
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  const _SpacedReviewSection(),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  const _AchievementSection(),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  const _SmartScheduleInsightSection(),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  _SessionTimelineSection(history: history),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  _WeeklyMomentumSection(history: history, progress: progress),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                ],
              );
            },
          ),
        ), // KeyedSubtree
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.progress,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final ratio = _parseWeeklyRatio(progress.weeklyConsistency);
    final percentage = (ratio * 100).round();
    final summaryLabel = _weeklySummaryLabel(
      context,
      progress.weeklyConsistency,
    );

    return Section(
      title: context.t(vi: 'Tóm tắt', en: 'Summary'),
      subtitle: summaryLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GrowMateLayout.contentGap),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                Row(
                  children: [
                    Text(
                      context.t(vi: 'Tóm tắt', en: 'Summary'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GrowMateLayout.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: ratio,
                    backgroundColor: colors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          Text(
            context.t(
              vi: progress.learningRhythm,
              en: 'Maintain a steady rhythm and focus on one high-impact topic for your next study sprint.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final strengths =
        progress.masteryMap
            .where((item) => item.score >= 3.0)
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));

    return Section(
      title: context.t(vi: 'Điểm mạnh', en: 'Strengths'),
      subtitle: context.t(
        vi: 'Chủ đề bạn nắm chắc',
        en: 'Topics you handle well',
      ),
      child: strengths.isEmpty
          ? Text(
              context.t(
                vi: 'Hoàn thành thêm vài phiên để AI nhận diện điểm mạnh.',
                en: 'Complete more sessions for AI to identify strengths.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: strengths
                  .take(3)
                  .toList(growable: false)
                  .asMap()
                  .entries
                  .map(
                    (entry) => ProgressBar(
                      label: _topicLabel(context, entry.value.topic),
                      value: entry.value.score / 4,
                      trailing: '${((entry.value.score / 4) * 100).round()}%',
                      caption: context.t(vi: 'Nắm chắc', en: 'Strong grasp'),
                      color: Theme.of(context).colorScheme.tertiary,
                      delayMs: 70 + entry.key * 45,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _WeaknessSection extends StatelessWidget {
  const _WeaknessSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final gaps =
        progress.masteryMap
            .where((item) => item.score < 3.0)
            .toList(growable: false)
          ..sort((a, b) => a.score.compareTo(b.score));

    final weakest = gaps.isEmpty ? null : gaps.first;
    final recommendation = weakest == null
        ? context.t(
            vi: 'Giữ nhịp và thêm bài nâng cao phiên tới.',
            en: 'Keep the rhythm, try advanced tasks next.',
          )
        : context.t(
            vi: 'Luyện ${weakest.topic} 15 phút, rồi kiểm tra 3 câu tính giờ.',
            en: 'Practice ${_topicLabel(context, weakest.topic)} for 15 min, then 3 timed Qs.',
          );

    return Section(
      title: context.t(vi: 'Điểm yếu cần ưu tiên', en: 'Priority weaknesses'),
      subtitle: context.t(
        vi: 'Tập trung 1 chủ đề yếu để tăng tự tin',
        en: 'Focus on one weak topic to boost confidence',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gaps.isEmpty)
            Text(
              context.t(
                vi: 'Chưa có lỗ hổng cần ưu tiên.',
                en: 'No priority gaps right now.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            ...gaps
                .take(3)
                .toList(growable: false)
                .asMap()
                .entries
                .map(
                  (entry) => ProgressBar(
                    label: _topicLabel(context, entry.value.topic),
                    value: entry.value.score / 4,
                    trailing: '${((entry.value.score / 4) * 100).round()}%',
                    caption: context.t(vi: 'Cần ôn lại', en: 'Needs review'),
                    color: Theme.of(context).colorScheme.secondary,
                    delayMs: 80 + entry.key * 45,
                  ),
                ),
          const SizedBox(height: GrowMateLayout.space8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GrowMateLayout.contentGap),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTimelineSection extends StatelessWidget {
  const _SessionTimelineSection({required this.history});

  final List<SessionHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Section(
      title: context.t(vi: 'Timeline phiên học', en: 'Session timeline'),
      subtitle: context.t(vi: 'Phiên gần đây', en: 'Recent sessions'),
      child: history.isEmpty
          ? Text(
              context.t(
                vi: 'Chưa có phiên nào. Hoàn thành phiên đầu tiên để xem.',
                en: 'No sessions yet. Complete one to see your timeline.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          : Column(
              children: history
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                entry.mode == 'recovery'
                                    ? Icons.spa_rounded
                                    : Icons.menu_book_rounded,
                                color: colors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _topicLabel(context, entry.topic),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dayLabel(context, entry.completedAt)} • ${entry.durationMinutes} ${context.t(vi: 'phút', en: 'min')} • ${context.t(vi: 'Tập trung', en: 'Focus')} ${entry.focusScore.toStringAsFixed(1)}/4',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _timelineNextActionText(context, entry),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w500,
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

class _SpacedReviewSection extends StatelessWidget {
  const _SpacedReviewSection();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();

    return StreamBuilder<List<SpacedReviewItem>>(
      stream: SpacedRepetitionRepository.instance.watchItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorStateWidget(
            message: context.t(
              vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
              en: 'Unable to load data. Please try again.',
            ),
            onRetry: () {
              context
                  .findAncestorStateOfType<_ProgressScreenState>()
                  ?.refresh();
            },
          );
        }

        if (!snapshot.hasData) {
          return const _LoadingStateWidget();
        }

        final items = snapshot.data ?? const <SpacedReviewItem>[];
        final dueItems =
            items
                .where((item) => !item.dueAt.isAfter(now))
                .toList(growable: false)
              ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

        return Section(
          title: context.t(vi: 'Ôn tập ngắt quãng', en: 'Spaced Repetition'),
          subtitle: context.t(
            vi: 'Ôn tập theo đường cong quên lãng',
            en: 'Review based on forgetting curve',
          ),
          child: dueItems.isEmpty
              ? Text(
                  context.t(
                    vi: 'Không có chủ đề cần ôn hôm nay.',
                    en: 'No topics due today.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: dueItems
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_topicLabel(context, item.topic)} • ${context.t(vi: 'chu kỳ', en: 'cycle')} ${item.intervalDays} ${context.t(vi: 'ngày', en: 'days')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
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
      },
    );
  }
}

class _AchievementSection extends StatelessWidget {
  const _AchievementSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AchievementBadge>>(
      stream: AchievementRepository.instance.watchUnlocked(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorStateWidget(
            message: context.t(
              vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
              en: 'Unable to load data. Please try again.',
            ),
            onRetry: () {
              context
                  .findAncestorStateOfType<_ProgressScreenState>()
                  ?.refresh();
            },
          );
        }

        if (!snapshot.hasData) {
          return const _LoadingStateWidget();
        }

        final badges = snapshot.data ?? const <AchievementBadge>[];

        return Section(
          title: context.t(vi: 'Huy hiệu thành tựu', en: 'Achievement badges'),
          subtitle: context.t(
            vi: 'Ghi nhận nỗ lực, không tạo áp lực',
            en: 'Celebrate effort, no pressure',
          ),
          child: badges.isEmpty
              ? Text(
                  context.t(
                    vi: 'Hoàn thành vài phiên để mở khóa huy hiệu.',
                    en: 'Complete sessions to unlock badges.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .take(6)
                      .map(
                        (badge) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconForBadge(badge.iconKey),
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                localizedBadgeTitle(context, badge),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        );
      },
    );
  }

  static IconData _iconForBadge(String key) {
    switch (key) {
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'psychology_alt':
        return Icons.psychology_alt_rounded;
      case 'calendar_month':
        return Icons.calendar_month_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }
}

class _SmartScheduleInsightSection extends StatelessWidget {
  const _SmartScheduleInsightSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudyScheduleItem>>(
      stream: StudyScheduleRepository.instance.watchItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorStateWidget(
            message: context.t(
              vi: 'Không tải được dữ liệu. Bạn thử lại nhé.',
              en: 'Unable to load data. Please try again.',
            ),
            onRetry: () {
              context
                  .findAncestorStateOfType<_ProgressScreenState>()
                  ?.refresh();
            },
          );
        }

        if (!snapshot.hasData) {
          return const _LoadingStateWidget();
        }

        final now = DateTime.now().toUtc();
        final items = snapshot.data ?? const <StudyScheduleItem>[];
        final pending =
            items.where((item) => !item.completed).toList(growable: false)
              ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

        final nearest = pending.isEmpty ? null : pending.first;

        return Section(
          title: context.t(vi: 'Lịch học thông minh', en: 'Smart Schedule'),
          subtitle: context.t(
            vi: 'Ưu tiên theo lịch thi và hạn nộp',
            en: 'Prioritize around exams & deadlines',
          ),
          child: nearest == null
              ? Text(
                  context.t(
                    vi: 'Chưa có mốc lịch. Thêm trong Cài đặt > Lịch thông minh.',
                    en: 'No milestones. Add in Settings > Smart Schedule.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _scheduleHint(context, nearest, now),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        );
      },
    );
  }

  static String _scheduleHint(
    BuildContext context,
    StudyScheduleItem item,
    DateTime now,
  ) {
    final daysLeft = item.dueAt.toLocal().difference(now.toLocal()).inDays;
    final typeLabel = item.type == 'exam'
        ? context.t(vi: 'bài thi', en: 'exam')
        : context.t(vi: 'hạn nộp', en: 'deadline');

    if (daysLeft <= 0) {
      return context.t(
        vi: 'Hôm nay: $typeLabel — ${item.title} (${item.subject}). Ôn 15–20 phút.',
        en: 'Today: $typeLabel — ${item.title} (${item.subject}). Review 15–20 min.',
      );
    }

    return context.t(
      vi: 'Còn $daysLeft ngày — $typeLabel: ${item.title} (${item.subject}).',
      en: '$daysLeft days — $typeLabel: ${item.title} (${item.subject}).',
    );
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

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Section(
      title: context.t(
        vi: 'Chưa có dữ liệu tiến trình',
        en: 'No progress data yet',
      ),
      subtitle: context.t(
        vi: 'Hoàn tất phiên đầu tiên để AI phân tích',
        en: 'Complete one session for AI analysis',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            context.t(
              vi: 'Sau phiên đầu, hệ thống sẽ hiển thị phân tích của bạn.',
              en: 'After your first session, analysis will appear here.',
            ),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(vi: 'Bắt đầu ngay', en: 'Get started'),
            onPressed: () => context.go(AppRoutes.quiz),
            trailing: Icon(Icons.play_arrow_rounded, color: colors.onPrimary),
          ),
        ],
      ),
    );
  }
}

double _parseWeeklyRatio(String value) {
  final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(value);
  if (match == null) {
    return 0.66;
  }

  final done = int.tryParse(match.group(1) ?? '') ?? 0;
  final total = int.tryParse(match.group(2) ?? '') ?? 0;
  if (total <= 0) {
    return 0.0;
  }

  return (done / total).clamp(0.0, 1.0);
}

String _weeklySummaryLabel(BuildContext context, String value) {
  final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(value);
  if (match == null) {
    return value;
  }

  final done = match.group(1) ?? '0';
  final total = match.group(2) ?? '0';
  return context.t(
    vi: '$done/$total buổi đã hoàn thành tuần này',
    en: '$done/$total sessions completed this week',
  );
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

String _timelineNextActionText(
  BuildContext context,
  SessionHistoryEntry entry,
) {
  final action = entry.nextAction.trim();

  if (context.isEnglish) {
    if (action.isEmpty || _containsVietnameseChars(action)) {
      return 'Next action: Review ${_topicLabel(context, entry.topic)} with 3 timed questions.';
    }
    return 'Next action: $action';
  }

  if (action.isEmpty || !_containsVietnameseChars(action)) {
    return 'Hành động kế tiếp: Ôn ${_topicLabel(context, entry.topic)} bằng 3 câu tính giờ.';
  }
  return 'Hành động kế tiếp: $action';
}

bool _containsVietnameseChars(String value) {
  return RegExp(
    r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
  ).hasMatch(value);
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

String _dayLabel(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  if (context.isEnglish) {
    return '${local.month}/${local.day} • $hour:$minute';
  }
  return '${local.day}/${local.month} • $hour:$minute';
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
