import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/zen_empty_state.dart';
import '../../../../shared/widgets/shimmer/shimmer_text.dart';
import '../../data/models/leaderboard_entry.dart';
import '../cubit/leaderboard_cubit.dart';
import '../cubit/leaderboard_state.dart';
import '../widgets/badge_showcase_grid.dart';
import '../widgets/leaderboard_card.dart';
import '../widgets/my_rank_banner.dart';
import '../widgets/period_tab_bar.dart';
import '../widgets/top_three_podium.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LeaderboardView();
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static String _periodLabel(BuildContext context, String period) {
    return switch (period) {
      'monthly' => context.t(vi: 'Tháng này', en: 'This month'),
      'all_time' => context.t(vi: 'Tổng tích lũy', en: 'All time'),
      _ => context.t(vi: 'Tuần này', en: 'This week'),
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LeaderboardCubit>();
      if (cubit.state.rankingStatus == LeaderboardLoadStatus.initial) {
        unawaited(cubit.loadLeaderboard());
      }
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) {
      return;
    }

    if (_tabController.index == 1) {
      final cubit = context.read<LeaderboardCubit>();
      if (cubit.state.badgesStatus == LeaderboardLoadStatus.initial) {
        unawaited(cubit.loadBadges());
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.t(vi: 'Bảng Xếp Hạng', en: 'Leaderboard'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              text: context.t(vi: 'Bảng xếp hạng', en: 'Leaderboard'),
            ),
            Tab(
              text: context.t(vi: 'Huy hiệu', en: 'Badges'),
            ),
          ],
        ),
      ),
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _RankingTab(
                    state: state,
                    myUserId: state.myRank?.userId ?? '',
                  ),
                  _BadgesTab(state: state),
                ],
              ),
              if (state.myRank != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: MyRankBanner(myEntry: state.myRank!),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.leaderboard,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({required this.state, required this.myUserId});

  final LeaderboardState state;
  final String myUserId;

  @override
  Widget build(BuildContext context) {
    final remainingEntries = state.entries
        .skip(state.entries.length >= 3 ? 3 : 0)
        .toList(growable: false);
    final topEntry = state.entries.isNotEmpty ? state.entries.first : null;

    if (state.isRankingLoading && state.entries.isEmpty) {
      return const _LeaderboardLoadingPane();
    }

    if (state.isRankingFailed && state.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ZenErrorCard(
            message: context.t(
              vi: 'Không tải được bảng xếp hạng',
              en: 'Could not load leaderboard',
            ),
            onRetry: () => context.read<LeaderboardCubit>().loadLeaderboard(
              period: state.selectedPeriod,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LeaderboardCubit>().loadLeaderboard(
        period: state.selectedPeriod,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _LeaderboardHeroCard(
            periodLabel: _LeaderboardViewState._periodLabel(
              context,
              state.selectedPeriod,
            ),
            myEntry: state.myRank,
            topEntry: topEntry,
          ),
          const SizedBox(height: 16),
          if (state.isRankingFailed) ...[
            ZenErrorCard(
              message: context.t(
                vi: 'Dữ liệu bảng xếp hạng có thể chưa mới nhất.',
                en: 'Leaderboard data may be stale.',
              ),
              onRetry: () => context.read<LeaderboardCubit>().loadLeaderboard(
                period: state.selectedPeriod,
              ),
            ),
            const SizedBox(height: 12),
          ],
          PeriodTabBar(
            selected: state.selectedPeriod,
            onSelected: (period) =>
                context.read<LeaderboardCubit>().switchPeriod(period),
          ),
          const SizedBox(height: 20),
          if (state.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const _EmptyLeaderboardCard(),
            ),
          if (state.entries.length >= 3) ...[
            _SectionCaption(
              title: context.t(vi: 'Top 3 nổi bật', en: 'Featured top 3'),
              subtitle: context.t(
                vi: 'Ba người đang dẫn đầu nhịp học hiện tại',
                en: 'Three learners leading this cycle',
              ),
            ),
            const SizedBox(height: 12),
            TopThreePodium(entries: state.entries.take(3).toList()),
            const SizedBox(height: 20),
          ],
          if (state.entries.length >= 3) ...[
            _SectionCaption(
              title: context.t(vi: 'Bảng chi tiết', en: 'Detailed board'),
              subtitle: context.t(
                vi: 'Danh sách từ hạng 4 trở xuống',
                en: 'Ranks from 4 downward',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (remainingEntries.isEmpty && state.entries.length >= 3)
            _RemainingRanksEmptyCard(
              message: context.t(
                vi: 'Hiện mới có đủ dữ liệu cho top 3. Khi có thêm người chơi, danh sách từ hạng 4 sẽ hiện ở đây.',
                en: 'Only the top 3 is available for now. When more players appear, ranks 4 and below will show here.',
              ),
            )
          else
            ...remainingEntries.map(
              (entry) =>
                  LeaderboardCard(entry: entry, isMe: entry.userId == myUserId),
            ),
        ],
      ),
    );
  }
}

class _RemainingRanksEmptyCard extends StatelessWidget {
  const _RemainingRanksEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: colors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHeroCard extends StatelessWidget {
  const _LeaderboardHeroCard({
    required this.periodLabel,
    required this.myEntry,
    required this.topEntry,
  });

  final String periodLabel;
  final LeaderboardEntry? myEntry;
  final LeaderboardEntry? topEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final stats = <({IconData icon, String label, String value})>[
      (
        icon: Icons.emoji_events_outlined,
        label: context.t(vi: 'Người dẫn đầu', en: 'Top player'),
        value:
            topEntry?.safeDisplayName ?? context.t(vi: 'Chưa có', en: 'None'),
      ),
      (
        icon: Icons.military_tech_outlined,
        label: context.t(vi: 'Hạng của bạn', en: 'Your rank'),
        value: myEntry != null
            ? '#${myEntry!.rank}'
            : context.t(vi: 'Chưa vào bảng', en: 'Unranked'),
      ),
      (
        icon: Icons.local_fire_department_outlined,
        label: context.t(vi: 'Streak hiện tại', en: 'Current streak'),
        value: myEntry != null
            ? context.t(
                vi: '${myEntry!.currentStreak} ngày',
                en: '${myEntry!.currentStreak} days',
              )
            : context.t(vi: '0 ngày', en: '0 days'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.62),
            colors.tertiaryContainer.withValues(alpha: 0.34),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t(
                        vi: 'Theo dõi nhịp tích XP và vị trí của bạn theo từng chu kỳ.',
                        en: 'Track XP momentum and your position across each cycle.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats
                .map(
                  (item) => _HeroMetricPill(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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

class _BadgeHeroCard extends StatelessWidget {
  const _BadgeHeroCard({required this.totalBadges, required this.earnedBadges});

  final int totalBadges;
  final int earnedBadges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secondaryContainer.withValues(alpha: 0.62),
            colors.primaryContainer.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: colors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(vi: 'Bộ sưu tập huy hiệu', en: 'Badge collection'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    vi: '$earnedBadges/$totalBadges mốc thành tựu đã mở khóa.',
                    en: '$earnedBadges/$totalBadges milestones unlocked.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
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

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.state});

  final LeaderboardState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBadgesLoading && state.badges.isEmpty) {
      return const _LeaderboardLoadingPane();
    }

    if (state.isBadgesFailed && state.badges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ZenErrorCard(
            message: context.t(
              vi: 'Không tải được huy hiệu',
              en: 'Could not load badges',
            ),
            onRetry: () =>
                context.read<LeaderboardCubit>().loadBadges(force: true),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<LeaderboardCubit>().loadBadges(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          _BadgeHeroCard(
            totalBadges: state.badges.length,
            earnedBadges: state.myBadges.length,
          ),
          const SizedBox(height: 16),
          if (state.isBadgesFailed) ...[
            ZenErrorCard(
              message: context.t(
                vi: 'Dữ liệu huy hiệu có thể chưa mới nhất.',
                en: 'Badges data may be stale.',
              ),
              onRetry: () =>
                  context.read<LeaderboardCubit>().loadBadges(force: true),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            context.t(vi: 'Huy hiệu của bạn', en: 'Your badges'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: '${state.myBadges.length}/${state.badges.length} badges đã đạt',
              en: '${state.myBadges.length}/${state.badges.length} badges earned',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (state.badges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ZenEmptyState(
                icon: Icons.workspace_premium_outlined,
                title: context.t(
                  vi: 'Chưa có huy hiệu nào hiển thị',
                  en: 'No badges to show yet',
                ),
                subtitle: context.t(
                  vi: 'Tiếp tục làm quiz và tích XP để mở khóa các mốc thành tựu đầu tiên.',
                  en: 'Keep taking quizzes and earning XP to unlock your first milestones.',
                ),
                primaryLabel: context.t(
                  vi: 'Làm quiz ngay',
                  en: 'Start a quiz',
                ),
                onPrimaryPressed: () => context.go(AppRoutes.quiz),
              ),
            )
          else
            BadgeShowcaseGrid(
              allBadges: state.badges,
              myBadges: state.myBadges,
            ),
        ],
      ),
    );
  }
}

class _LeaderboardLoadingPane extends StatelessWidget {
  const _LeaderboardLoadingPane();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerText(width: 200, height: 16),
          SizedBox(height: 12),
          ShimmerText(width: double.infinity, height: 12),
          SizedBox(height: 8),
          ShimmerText(width: 160, height: 12),
          SizedBox(height: 8),
          ShimmerText(width: double.infinity, height: 12),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardCard extends StatelessWidget {
  const _EmptyLeaderboardCard();

  @override
  Widget build(BuildContext context) {
    return ZenEmptyState(
      icon: Icons.emoji_events_outlined,
      title: context.t(
        vi: 'Bảng xếp hạng đang chờ người mở màn',
        en: 'The leaderboard is waiting for its first entry',
      ),
      subtitle: context.t(
        vi: 'Làm một bài quiz để tích XP và xuất hiện trên bảng xếp hạng.',
        en: 'Take a quiz to earn XP and show up on the leaderboard.',
      ),
      primaryLabel: context.t(vi: 'Làm quiz ngay', en: 'Start a quiz'),
      onPrimaryPressed: () => context.go(AppRoutes.quiz),
      centered: true,
    );
  }
}
