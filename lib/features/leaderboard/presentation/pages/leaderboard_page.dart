import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/shimmer/shimmer_text.dart';
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
        title: Text(
          context.t(vi: '🏆 Bảng Xếp Hạng', en: '🏆 Leaderboard'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
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
              child: Text(
                context.t(
                  vi: 'Chưa có dữ liệu bảng xếp hạng.',
                  en: 'No leaderboard data yet.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (state.entries.length >= 3) ...[
            TopThreePodium(entries: state.entries.take(3).toList()),
            const SizedBox(height: 20),
          ],
          ...state.entries
              .skip(state.entries.length >= 3 ? 3 : 0)
              .map(
                (entry) => LeaderboardCard(
                  entry: entry,
                  isMe: entry.userId == myUserId,
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
              child: Text(
                context.t(
                  vi: 'Chưa có dữ liệu huy hiệu.',
                  en: 'No badge data yet.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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
