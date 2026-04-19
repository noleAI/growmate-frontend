import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../session/data/models/session_history_entry.dart';
import '../../../session/data/repositories/session_history_repository.dart';
import '../../../diagnosis/data/repositories/diagnosis_snapshot_cache_repository.dart';
import '../../../leaderboard/data/repositories/leaderboard_repository.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../../shared/widgets/ambient/ambient_gradient.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/confidence/confidence_arc.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/streak/streak_popup.dart';
import '../../../../shared/widgets/shimmer/shimmer_card.dart';
import '../../../../shared/widgets/shimmer/shimmer_text.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../../../../shared/models/feature_availability.dart';
import '../../../inspection/presentation/cubit/inspection_cubit.dart';
import '../../../inspection/presentation/widgets/inspection_bottom_sheet.dart';
import '../../../wellness/presentation/widgets/mood_check_dialog.dart';
import '../../../session_recovery/data/models/pending_session.dart';
import '../../../session_recovery/data/repositories/session_recovery_repository.dart';
import '../cubit/home_hydration_cubit.dart';
import '../cubit/home_hydration_state.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_cubit.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_state.dart';
import '../../../mascot/presentation/pages/mascot_selection_page.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _onboardingDismissed = true;
  HomeHydrationCubit? _homeHydrationCubit;
  bool _didInitializeHydration = false;

  static const String _onboardingKey = 'onboarding_dismissed';

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
    _checkDailyStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeHydration) {
      return;
    }

    _didInitializeHydration = true;
    _homeHydrationCubit = HomeHydrationCubit(
      historyRepository: SessionHistoryRepository.instance,
      diagnosisSnapshotCacheRepository:
          DiagnosisSnapshotCacheRepository.instance,
      sessionRecoveryRepository: _tryReadSessionRecovery(context),
    )..hydrate();
  }

  Future<void> _checkDailyStreak() async {
    LeaderboardRepository? repo;
    LeaderboardCubit? lbCubit;
    try {
      repo = context.read<LeaderboardRepository>();
    } catch (_) {
      repo = null;
    }
    try {
      lbCubit = context.read<LeaderboardCubit>();
    } catch (_) {
      lbCubit = null;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final lastShown = prefs.getString('streak_popup_date');
    // Prevent duplicate daily-login XP calls in the same local day.
    if (lastShown == today) {
      return;
    }

    // Optimistic guard: mark the local day before hitting the API.
    await prefs.setString('streak_popup_date', today);

    int streakDays = 1;
    int xpBonus = 10;
    var shouldShowPopup = false;
    try {
      if (repo == null) {
        throw StateError('LeaderboardRepository is unavailable');
      }
      final response = await repo.addXp(eventType: 'daily_login');
      streakDays = response.currentStreak;
      xpBonus = response.xpAdded;
      // Show only when backend actually grants new XP for this login.
      shouldShowPopup = xpBonus > 0 && streakDays > 0;
    } catch (_) {
      if (!mounted) return;
      // Fallback: read streak from cubit or local counter.
      try {
        if (lbCubit != null) {
          final lbState = lbCubit.state;
          if (lbState.myRank != null) {
            streakDays = lbState.myRank!.currentStreak;
          } else {
            await lbCubit.loadLeaderboard();
            final refreshed = lbCubit.state;
            if (refreshed.myRank != null) {
              streakDays = refreshed.myRank!.currentStreak;
            }
          }
        }
      } catch (_) {
        streakDays = (prefs.getInt('streak_days') ?? 0) + 1;
        await prefs.setInt('streak_days', streakDays);
      }
      xpBonus = streakDays * 10;
      shouldShowPopup = streakDays > 0;
    }
    if (!mounted || !shouldShowPopup) {
      return;
    }
    if (!mounted) {
      return;
    }

    StreakPopup.show(
      context,
      streakDays: streakDays,
      xpBonus: xpBonus,
      weekDays: _buildWeekStreakMarkers(now: now, streakDays: streakDays),
    );
  }

  static List<bool> _buildWeekStreakMarkers({
    required DateTime now,
    required int streakDays,
  }) {
    final markers = List<bool>.filled(7, false);
    final visibleDays = streakDays <= 0 ? 0 : (streakDays > 7 ? 7 : streakDays);

    for (var offset = 0; offset < visibleDays; offset += 1) {
      final rawIndex = now.weekday - 1 - offset;
      final wrappedIndex = ((rawIndex % 7) + 7) % 7;
      markers[wrappedIndex] = true;
    }

    return markers;
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

  Future<void> _handleRefresh(BuildContext context) async {
    final hydrationRefresh = context.read<HomeHydrationCubit>().refresh();

    AgenticSessionCubit? agenticCubit;
    try {
      agenticCubit = context.read<AgenticSessionCubit>();
    } catch (_) {
      agenticCubit = null;
    }

    if (agenticCubit == null) {
      await hydrationRefresh;
      return;
    }

    await Future.wait<void>([
      hydrationRefresh,
      agenticCubit.refreshHomeMission(),
    ]);
  }

  @override
  void dispose() {
    _homeHydrationCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hydrationCubit = _homeHydrationCubit;
    final theme = Theme.of(context);
    if (hydrationCubit == null) {
      return const SizedBox.shrink();
    }

    return BlocProvider<HomeHydrationCubit>.value(
      value: hydrationCubit,
      child: BlocBuilder<HomeHydrationCubit, HomeHydrationState>(
        builder: (context, hydrationState) {
          final history = hydrationState.history;
          final latestSession = hydrationState.latestSession;
          final pendingSession = hydrationState.pendingSession;
          final hasPendingSession = pendingSession?.hasPending == true;
          return Scaffold(
            backgroundColor: AmbientGradient.colorFor(
              theme.scaffoldBackgroundColor,
              hydrationState.emotion,
            ),
            body: ZenPageContainer(
              includeBottomSafeArea: false,
              child: RefreshIndicator(
                onRefresh: () => _handleRefresh(context),
                child: ListView(
                  children: [
                    _buildTopAppBar(context),

                    const SizedBox(height: GrowMateLayout.space16),
                    _HomeHeader(
                      dateLabel: _dateLabel(context, DateTime.now()),
                      hydrationStatus: hydrationState.status,
                      pendingSession: pendingSession,
                      showStatusChip: !hasPendingSession,
                    ),

                    if (hasPendingSession) ...[
                      const SizedBox(height: GrowMateLayout.space16),
                      FadeSlideIn(
                        delayMs: 0,
                        child: _PendingHeroCard(
                          pendingSession: pendingSession!,
                          onResume: (pending) => _resumePendingSession(
                            context: context,
                            pending: pending,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: GrowMateLayout.contentGap),

                    // Recovery mode indicator (subtle) — only when AgenticSessionCubit is present
                    Builder(
                      builder: (innerCtx) {
                        AgenticSessionCubit? agenticCubit;
                        try {
                          agenticCubit = innerCtx.read<AgenticSessionCubit>();
                        } catch (_) {
                          agenticCubit = null;
                        }
                        if (agenticCubit == null) {
                          return const SizedBox.shrink();
                        }

                        return BlocBuilder<
                          AgenticSessionCubit,
                          AgenticSessionState
                        >(
                          bloc: agenticCubit,
                          builder: (context, agenticState) {
                            if (!agenticState.isRecovery) {
                              return const SizedBox.shrink();
                            }
                            final colors = Theme.of(context).colorScheme;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.self_improvement,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        context.t(
                                          vi: 'Chế độ phục hồi đang bật — thử một bài ngắn để giảm áp lực.',
                                          en: 'Recovery mode active — try a short, gentle activity.',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.recovery),
                                      child: Text(
                                        context.t(vi: 'Xem', en: 'View'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    if (hydrationState.showEmptyOnboarding &&
                        !_onboardingDismissed) ...[
                      FadeSlideIn(
                        delayMs: 0,
                        child: _OnboardingCard(onDismiss: _dismissOnboarding),
                      ),
                      const SizedBox(height: GrowMateLayout.space12),
                    ],

                    // ── AI State Card (focal point) ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      child: switch (hydrationState.status) {
                        HomeHydrationStatus.loading => _ThinkingHero(
                          theme: theme,
                        ),
                        HomeHydrationStatus.error => FadeSlideIn(
                          delayMs: 150,
                          child: _HydrationErrorHero(
                            onRetry: context.read<HomeHydrationCubit>().refresh,
                          ),
                        ),
                        _ when hasPendingSession => const SizedBox.shrink(),
                        HomeHydrationStatus.ready => FadeSlideIn(
                          delayMs: 150,
                          child: _AiStateCard(
                            latestSession: latestSession,
                            confidence: hydrationState.confidence,
                            emotion: hydrationState.emotion,
                            onStartSession: () => context.push(AppRoutes.quiz),
                          ),
                        ),
                        HomeHydrationStatus.empty => FadeSlideIn(
                          delayMs: 150,
                          child: const _EmptyHeroCard(),
                        ),
                      },
                    ),

                    const SizedBox(height: GrowMateLayout.space12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      child:
                          hydrationState.status == HomeHydrationStatus.loading
                          ? const _AgentMissionLoadingCard()
                          : _AgentMissionCard(hydrationState: hydrationState),
                    ),

                    const SizedBox(height: GrowMateLayout.breath),

                    // ── Pulse Metrics ──
                    if (hydrationState.hasReadyHistory)
                      FadeSlideIn(
                        delayMs: 250,
                        child: _PulseMetrics(history: history),
                      ),

                    const SizedBox(height: GrowMateLayout.breath),

                    // ── Quick Actions ──
                    FadeSlideIn(
                      delayMs: 350,
                      child: const _FeatureHubSection(),
                    ),

                    const SizedBox(height: GrowMateLayout.breath),

                    // Đã loại bỏ mục "Phân tích AI gần nhất"
                  ],
                ),
              ),
            ),
            bottomNavigationBar: GrowMateBottomNavBar(
              currentTab: GrowMateTab.today,
              onTabSelected: (tab) => handleTabNavigation(context, tab),
            ),
            floatingActionButton: _ChatFab(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
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
      return const GrowMateTopAppBar(appleStyle: true);
    }

    return StreamBuilder<InspectionState>(
      stream: inspectionCubit.stream,
      initialData: inspectionCubit.state,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ZenErrorCard(
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

  /// Safely reads [SessionRecoveryRepository] from the widget tree.
  /// Returns null when the repository is not registered (mock mode).
  static SessionRecoveryRepository? _tryReadSessionRecovery(
    BuildContext context,
  ) {
    try {
      return context.read<SessionRecoveryRepository>();
    } catch (_) {
      return null;
    }
  }

  void _resumePendingSession({
    required BuildContext context,
    required PendingSession pending,
  }) {
    final queryParameters = <String, String>{'resume': '1'};

    final sessionId = pending.sessionId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      queryParameters['session_id'] = sessionId;
    }

    // Always use lastQuestionIndex to ensure we resume from the current question
    // being worked on, not the next one. This prevents skipping questions on resume.
    final resumeIndex = pending.lastQuestionIndex ?? pending.nextQuestionIndex;
    if (resumeIndex != null && resumeIndex >= 0) {
      queryParameters['next_index'] = resumeIndex.toString();
    }

    final mode = pending.mode?.trim();
    if (mode != null && mode.isNotEmpty) {
      queryParameters['mode'] = mode;
    }

    if (pending.pauseState != null) {
      queryParameters['pause_state'] = pending.pauseState! ? '1' : '0';
    }

    if (pending.resumeContextVersion != null) {
      queryParameters['resume_context_version'] = pending.resumeContextVersion!
          .toString();
    }

    final location = Uri(
      path: AppRoutes.quiz,
      queryParameters: queryParameters,
    ).toString();

    context.go(location);
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
      padding: const EdgeInsets.all(GrowMateLayout.breath),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerCard(height: 72, width: 72, radius: 36),
              const SizedBox(width: GrowMateLayout.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerText(width: 80, height: 12),
                    SizedBox(height: 8),
                    ShimmerText(width: 140, height: 16),
                    SizedBox(height: 6),
                    ShimmerText(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space16),
          const ShimmerText(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          const ShimmerText(width: 200, height: 12),
          const SizedBox(height: GrowMateLayout.space16),
          const ShimmerCard(height: 48, radius: 16),
        ],
      ),
    );
  }
}

/// ── AI State Card (focal point of the Living Dashboard) ──
///
/// Combines: confidence arc, emotion state, topic suggestion, and CTA.
class _AiStateCard extends StatelessWidget {
  const _AiStateCard({
    required this.latestSession,
    required this.confidence,
    required this.emotion,
    required this.onStartSession,
  });

  final SessionHistoryEntry? latestSession;
  final double confidence;
  final String emotion;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (latestSession == null) {
      return const _EmptyHeroCard();
    }

    final topic = latestSession!.topic.trim().isEmpty
        ? context.t(vi: 'Đạo hàm cơ bản', en: 'Basic Derivatives')
        : latestSession!.topic;
    final reason = latestSession!.nextAction.trim().isEmpty
        ? context.t(
            vi: 'AI cập nhật gợi ý sau phiên tiếp theo.',
            en: 'AI updates after your next session.',
          )
        : latestSession!.nextAction;

    return Container(
      key: const ValueKey<String>('ai-state-card'),
      width: double.infinity,
      padding: GrowMateLayout.cardPaddingAi,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
        border: Border.all(
          color: GrowMateColors.confidenceColor(
            confidence,
            Theme.of(context).brightness,
          ).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: GrowMateColors.confidenceColor(
              confidence,
              Theme.of(context).brightness,
            ).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: Confidence Arc + State ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfidenceArc(confidence: confidence, size: 72, strokeWidth: 5),
              const SizedBox(width: GrowMateLayout.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmotionTag(emotion: emotion),
                    const SizedBox(height: 6),
                    Text(
                      context.t(
                        vi: 'AI gợi ý cho bạn',
                        en: 'AI suggests for you',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: GrowMateLayout.space12),

          // ── Reason ──
          Text(
            reason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: GrowMateLayout.space16),

          // ── CTA Row ──
          ZenButton(
            label: context.t(
              vi: 'Bắt đầu phiên tiếp theo',
              en: 'Start next session',
            ),
            onPressed: onStartSession,
          ),
        ],
      ),
    );
  }
}

class _PendingHeroCard extends StatelessWidget {
  const _PendingHeroCard({
    required this.pendingSession,
    required this.onResume,
  });

  final PendingSession pendingSession;
  final ValueChanged<PendingSession> onResume;

  String _progressLabel(BuildContext context) {
    final progress = pendingSession.progressPercent;
    if (progress != null) {
      return context.t(vi: '$progress% hoàn thành', en: '$progress% complete');
    }

    final total = pendingSession.totalQuestions;
    final index =
        pendingSession.lastQuestionIndex ?? pendingSession.nextQuestionIndex;
    if (total != null && total > 0 && index != null && index >= 0) {
      final derived = (((index + 1) / total) * 100).clamp(0, 100).toInt();
      return context.t(vi: '$derived% hoàn thành', en: '$derived% complete');
    }

    return context.t(vi: 'Sẵn sàng tiếp tục', en: 'Ready to resume');
  }

  String _nextQuestionLabel(BuildContext context) {
    final index =
        pendingSession.lastQuestionIndex ?? pendingSession.nextQuestionIndex;
    final total = pendingSession.totalQuestions;
    if (index == null || index < 0) {
      return context.t(
        vi: 'Câu tiếp theo chưa rõ',
        en: 'Next question unknown',
      );
    }
    final question = index + 1;
    if (total != null && total > 0) {
      return context.t(
        vi: 'Câu $question/$total',
        en: 'Question $question/$total',
      );
    }
    return context.t(vi: 'Câu $question', en: 'Question $question');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey<String>('ai-hero-pending'),
      width: double.infinity,
      padding: GrowMateLayout.cardPaddingAi,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
        border: Border.all(color: colors.tertiary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: colors.tertiary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.tertiary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_rounded,
                  color: colors.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: GrowMateLayout.space12),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Tiếp tục phiên học đang dở',
                    en: 'Continue your unfinished session',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            context.t(
              vi: 'Giữ nhịp học hiện tại bằng cách quay lại đúng câu bạn đang làm.',
              en: 'Keep your momentum by resuming exactly where you left off.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PendingChip(
                label: _progressLabel(context),
                color: colors.tertiary,
              ),
              _PendingChip(
                label: _nextQuestionLabel(context),
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(vi: 'Tiếp tục phiên học', en: 'Resume session'),
            onPressed: () => onResume(pendingSession),
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HydrationErrorHero extends StatelessWidget {
  const _HydrationErrorHero({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey<String>('ai-hero-error'),
      width: double.infinity,
      padding: GrowMateLayout.cardPaddingAi,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
        border: Border.all(color: colors.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.error.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: colors.error,
                ),
              ),
              const SizedBox(width: GrowMateLayout.space8),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Chưa xác nhận được dữ liệu mới',
                    en: 'Latest data not confirmed yet',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            context.t(
              vi: 'Home đang chờ dữ liệu học mới từ server trước khi hiển thị gợi ý AI.',
              en: 'Home is waiting for fresh server data before showing AI guidance.',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(vi: 'Thử tải lại', en: 'Retry'),
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.dateLabel,
    required this.hydrationStatus,
    required this.pendingSession,
    this.showStatusChip = true,
  });

  final String dateLabel;
  final HomeHydrationStatus hydrationStatus;
  final PendingSession? pendingSession;
  final bool showStatusChip;

  String _greeting(BuildContext context, DateTime now) {
    if (context.isEnglish) {
      if (now.hour < 12) return 'Good morning';
      if (now.hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
    if (now.hour < 12) return 'Chào buổi sáng';
    if (now.hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  (String, Color) _status(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasPending = pendingSession?.hasPending == true;

    if (hydrationStatus == HomeHydrationStatus.loading) {
      return (
        context.t(
          vi: 'Đang đồng bộ dữ liệu học',
          en: 'Syncing your learning data',
        ),
        colors.onSurfaceVariant,
      );
    }
    if (hydrationStatus == HomeHydrationStatus.error) {
      return (
        context.t(
          vi: 'Dữ liệu chưa xác nhận, thử tải lại',
          en: 'Data not confirmed yet, retry needed',
        ),
        colors.error,
      );
    }
    if (hasPending) {
      return (
        context.t(
          vi: 'Bạn có phiên học đang dở',
          en: 'You have an unfinished session',
        ),
        colors.tertiary,
      );
    }
    if (hydrationStatus == HomeHydrationStatus.ready) {
      return (
        context.t(
          vi: 'Sẵn sàng cho phiên tiếp theo',
          en: 'Ready for your next session',
        ),
        colors.primary,
      );
    }
    return (
      context.t(
        vi: 'Bắt đầu phiên đầu tiên để mở insight',
        en: 'Start your first session to unlock insights',
      ),
      colors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final greeting = _greeting(context, DateTime.now());
    final (statusText, statusColor) = _status(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showStatusChip) ...[
          const SizedBox(height: GrowMateLayout.space8),
          FractionallySizedBox(
            widthFactor: 1,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmotionTag extends StatelessWidget {
  const _EmotionTag({required this.emotion});

  final String emotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (String emoji, String label) = switch (emotion) {
      'focused' => ('🟢', context.t(vi: 'Tập trung', en: 'Focused')),
      'confused' => ('🟡', context.t(vi: 'Hơi mệt', en: 'Slightly tired')),
      'exhausted' => ('🔴', context.t(vi: 'Cần nghỉ', en: 'Needs rest')),
      'frustrated' => ('🟠', context.t(vi: 'Khó chịu', en: 'Frustrated')),
      _ => ('🟢', context.t(vi: 'Tập trung', en: 'Focused')),
    };

    final brightness = Theme.of(context).brightness;
    final color = switch (emotion) {
      'focused' => GrowMateColors.focused(brightness),
      'confused' => GrowMateColors.confused(brightness),
      'exhausted' => GrowMateColors.exhausted(brightness),
      'frustrated' => GrowMateColors.frustrated(brightness),
      _ => GrowMateColors.focused(brightness),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Pulse Metrics — animated circles replacing flat stat boxes ──
class _PulseMetrics extends StatelessWidget {
  const _PulseMetrics({required this.history});

  final List<SessionHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();

    final streak = _calculateStreak(history, now);
    final sessionsToday = _sessionsToday(history, now);
    final focusLabel = _focusLabel(context, history, now);

    return Row(
      children: [
        Expanded(
          child: _PulseCircle(
            value: '$streak',
            label: context.t(vi: 'ngày', en: 'days'),
            icon: Icons.local_fire_department_rounded,
            accent: colors.tertiary,
            staggerDelayMs: 0,
          ),
        ),
        const SizedBox(width: GrowMateLayout.space12),
        Expanded(
          child: _PulseCircle(
            value: '$sessionsToday',
            label: context.t(vi: 'phiên', en: 'sessions'),
            icon: Icons.task_alt_rounded,
            accent: GrowMateColors.aiCore(Theme.of(context).brightness),
            staggerDelayMs: 120,
          ),
        ),
        const SizedBox(width: GrowMateLayout.space12),
        Expanded(
          child: _PulseCircle(
            value: focusLabel,
            label: context.t(vi: 'tập trung', en: 'focus'),
            icon: Icons.bolt_rounded,
            accent: colors.primary,
            staggerDelayMs: 240,
          ),
        ),
      ],
    );
  }

  static int _calculateStreak(List<SessionHistoryEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;
    final activeDays = entries
        .map((e) => _dateOnly(e.completedAt.toLocal()))
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
    return entries.where((e) {
      return _dateOnly(e.completedAt.toLocal()) == today;
    }).length;
  }

  static String _focusLabel(
    BuildContext context,
    List<SessionHistoryEntry> entries,
    DateTime now,
  ) {
    final threshold = now.toUtc().subtract(const Duration(hours: 24));
    final recent = entries
        .where((e) => !e.completedAt.toUtc().isBefore(threshold))
        .toList(growable: false);
    if (recent.isEmpty) return '—';
    final average =
        recent.map((e) => e.focusScore).reduce((a, b) => a + b) / recent.length;
    if (average >= 3.5) return context.t(vi: 'Tốt', en: 'Good');
    if (average >= 2.5) return context.t(vi: 'Ổn', en: 'Okay');
    return context.t(vi: 'Cần nghỉ', en: 'Need rest');
  }

  static DateTime _dateOnly(DateTime v) => DateTime(v.year, v.month, v.day);
}

class _PulseCircle extends StatefulWidget {
  const _PulseCircle({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    this.staggerDelayMs = 0,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final int staggerDelayMs;

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _enterController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _enterOpacity;
  late final Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _enterOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
        );

    Future.delayed(Duration(milliseconds: widget.staggerDelayMs), () {
      if (mounted) {
        _enterController.forward();
        _breatheController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusSm),
        border: Border.all(color: widget.accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(widget.icon, size: 18, color: widget.accent),
          ),
          const SizedBox(height: 8),
          Text(
            widget.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return SlideTransition(
      position: _enterSlide,
      child: FadeTransition(
        opacity: _enterOpacity,
        child: ScaleTransition(scale: _scaleAnim, child: child),
      ),
    );
  }
}

class _AgentMissionCard extends StatelessWidget {
  const _AgentMissionCard({required this.hydrationState});

  final HomeHydrationState hydrationState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    AgenticSessionState? agenticState;
    try {
      agenticState = context.watch<AgenticSessionCubit>().state;
    } catch (_) {
      agenticState = null;
    }

    final pending = hydrationState.pendingSession;
    final latestSession = hydrationState.latestSession;
    final diagnosisSnapshot = hydrationState.diagnosisSnapshot;
    final hasPendingSession = pending?.hasPending == true;
    final hasLiveDashboard = agenticState?.latestDashboard != null;
    // Feature availability badge removed during UI cleanup.

    final reflection = agenticState?.latestReflection;
    final confidence =
        (hasLiveDashboard
            ? agenticState?.latestDashboard?.academic.confidence
            : diagnosisSnapshot?.confidenceScore) ??
        latestSession?.confidenceScore ??
        hydrationState.confidence;
    final confidenceLabel = '${(confidence.clamp(0.0, 1.0) * 100).round()}%';
    final stageLabel = _resolveStageLabel(
      context,
      agenticState: agenticState,
      hasPendingSession: hasPendingSession,
    );
    final nextCheckpoint = _resolveNextCheckpoint(
      context,
      agenticState: agenticState,
      pending: pending,
      latestSession: latestSession,
    );

    return ZenCard(
      radius: GrowMateLayout.cardRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(vi: 'Nhiệm vụ của Agent', en: 'Agent Mission'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // Đã xóa text nhỏ mô tả quy trình dưới 'Nhiệm vụ của Agent' theo yêu cầu
                  ],
                ),
              ),
              // FeatureAvailabilityBadge removed as per UI cleanup request
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MissionMetricChip(
                label: context.t(vi: 'Pha', en: 'Phase'),
                value: stageLabel,
              ),
              _MissionMetricChip(
                label: context.t(vi: 'Độ tin cậy', en: 'Confidence'),
                value: confidenceLabel,
              ),
              if (pending?.hasPending == true)
                _MissionMetricChip(
                  label: context.t(vi: 'Đang chờ', en: 'Pending'),
                  value: context.t(vi: 'Có', en: 'Yes'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _MissionLine(
            title: context.t(vi: 'Mốc tiếp theo', en: 'Next checkpoint'),
            body: nextCheckpoint,
          ),
          if (reflection != null) ...[
            const SizedBox(height: 10),
            _MissionLine(
              title: context.t(vi: 'Phản tư gần nhất', en: 'Latest reflection'),
              body: reflection.recommendation.trim().isEmpty
                  ? reflection.reasoning
                  : reflection.recommendation,
            ),
          ],
          if (hydrationState.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              hydrationState.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _resolveStageLabel(
    BuildContext context, {
    required AgenticSessionState? agenticState,
    required bool hasPendingSession,
  }) {
    if (hasPendingSession) {
      if (hydrationState.pendingSession?.pauseState == true) {
        return context.t(vi: 'Tạm dừng', en: 'Paused');
      }
      return switch (agenticState?.phase) {
        AgenticPhase.processing => context.t(
          vi: 'Đang xử lý',
          en: 'Processing',
        ),
        AgenticPhase.hitlPending => context.t(
          vi: 'Chờ HITL',
          en: 'HITL pending',
        ),
        AgenticPhase.recovery => context.t(vi: 'Phục hồi', en: 'Recovery'),
        AgenticPhase.error => context.t(vi: 'Lỗi', en: 'Error'),
        _ => context.t(vi: 'Sẵn sàng tiếp tục', en: 'Ready to resume'),
      };
    }

    if (agenticState?.latestDashboard != null) {
      return _phaseLabel(context, agenticState?.phase);
    }

    if (hydrationState.hasReadyHistory ||
        hydrationState.diagnosisSnapshot != null ||
        hydrationState.hasRemoteHistoryConfirmation) {
      return context.t(vi: 'Sẵn sàng', en: 'Ready');
    }

    return context.t(vi: 'Agent đang nghỉ', en: 'Agent idle');
  }

  String _resolveNextCheckpoint(
    BuildContext context, {
    required AgenticSessionState? agenticState,
    required PendingSession? pending,
    required SessionHistoryEntry? latestSession,
  }) {
    if (pending?.hasPending == true) {
      return context.t(
        vi: 'Tiếp tục từ câu ${((pending?.lastQuestionIndex ?? 0) + 1)}',
        en: 'Resume at Q${((pending?.lastQuestionIndex ?? 0) + 1)}',
      );
    }

    final liveAction = agenticState?.currentAction?.trim();
    if (agenticState?.latestDashboard != null &&
        liveAction != null &&
        liveAction.isNotEmpty) {
      return _humanizeAction(context, liveAction);
    }

    final suggestedTopic = hydrationState.diagnosisSnapshot?.nextSuggestedTopic
        .trim();
    if (suggestedTopic != null && suggestedTopic.isNotEmpty) {
      return suggestedTopic;
    }

    final nextAction = latestSession?.nextAction.trim();
    if (nextAction != null && nextAction.isNotEmpty) {
      return nextAction;
    }

    return context.t(
      vi: 'Bắt đầu quiz để AI lập kế hoạch',
      en: 'Start a quiz so AI can plan',
    );
  }

  String _phaseLabel(BuildContext context, AgenticPhase? phase) {
    return switch (phase) {
      null => context.t(vi: 'Agent đang nghỉ', en: 'Agent idle'),
      AgenticPhase.idle => context.t(vi: 'Nhàn rỗi', en: 'Idle'),
      AgenticPhase.ready => context.t(vi: 'Sẵn sàng', en: 'Ready'),
      AgenticPhase.interacting => context.t(
        vi: 'Đang tương tác',
        en: 'Interacting',
      ),
      AgenticPhase.processing => context.t(vi: 'Đang xử lý', en: 'Processing'),
      AgenticPhase.hitlPending => context.t(vi: 'Chờ HITL', en: 'HITL pending'),
      AgenticPhase.recovery => context.t(vi: 'Phục hồi', en: 'Recovery'),
      AgenticPhase.completed => context.t(vi: 'Hoàn tất', en: 'Completed'),
      AgenticPhase.error => context.t(vi: 'Lỗi', en: 'Error'),
    };
  }

  String _humanizeAction(BuildContext context, String action) {
    return switch (action) {
      'next_question' => context.t(
        vi: 'Tiếp tục sang câu hỏi tiếp theo',
        en: 'Continue to the next question',
      ),
      'show_hint' => context.t(
        vi: 'Xem một gợi ý ngắn trước khi làm tiếp',
        en: 'Review a short hint before continuing',
      ),
      'de_stress' || 'recovery' || 'suggest_break' => context.t(
        vi: 'Chuyển sang nhịp học nhẹ hơn để hồi phục',
        en: 'Switch to a lighter recovery step',
      ),
      'hitl_pending' || 'hitl' => context.t(
        vi: 'Chờ xác nhận cho bước can thiệp tiếp theo',
        en: 'Wait for confirmation on the next intervention',
      ),
      _ => action.replaceAll('_', ' '),
    };
  }
}

class _AgentMissionLoadingCard extends StatelessWidget {
  const _AgentMissionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return ZenCard(
      key: const ValueKey<String>('agent-mission-loading'),
      radius: GrowMateLayout.cardRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              ShimmerCard(height: 36, width: 36, radius: 12),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 150, height: 16),
                    SizedBox(height: 6),
                    ShimmerText(width: 220, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ShimmerCard(height: 28, width: 92, radius: 16),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShimmerCard(height: 36, width: 108, radius: 18),
              ShimmerCard(height: 36, width: 116, radius: 18),
            ],
          ),
          SizedBox(height: 12),
          ShimmerText(width: 100, height: 12),
          SizedBox(height: 8),
          ShimmerText(width: double.infinity, height: 14),
          SizedBox(height: 6),
          ShimmerText(width: 180, height: 14),
        ],
      ),
    );
  }
}

class _MissionMetricChip extends StatelessWidget {
  const _MissionMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionLine extends StatelessWidget {
  const _MissionLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FeatureHubSection extends StatelessWidget {
  const _FeatureHubSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final primary = <_FeatureShortcutData>[
      _FeatureShortcutData(
        icon: Icons.edit_note_rounded,
        label: context.t(vi: 'Làm bài', en: 'Quiz'),
        color: colors.primary,
        route: AppRoutes.quiz,
        availability: FeatureAvailability.server,
      ),
      _FeatureShortcutData(
        icon: Icons.refresh_rounded,
        label: context.t(vi: 'Ôn tập', en: 'Review'),
        color: colors.tertiary,
        route: AppRoutes.spacedReview,
        availability: FeatureAvailability.server,
      ),
      _FeatureShortcutData(
        icon: Icons.timer_rounded,
        label: context.t(vi: 'Tập trung', en: 'Focus'),
        color: const Color(0xFF2563EB),
        route: AppRoutes.focusTimer,
        availability: FeatureAvailability.server,
      ),
    ];

    final secondary = <_FeatureShortcutData>[
      _FeatureShortcutData(
        icon: Icons.map_rounded,
        label: context.t(vi: 'Lộ trình', en: 'Roadmap'),
        color: const Color(0xFF0EA5E9),
        route: AppRoutes.thptRoadmap,
        availability: FeatureAvailability.beta,
      ),
      _FeatureShortcutData(
        icon: Icons.calendar_month_rounded,
        label: context.t(vi: 'Lịch học', en: 'Schedule'),
        color: const Color(0xFFF59E0B),
        route: AppRoutes.schedule,
        availability: FeatureAvailability.beta,
      ),
      _FeatureShortcutData(
        icon: Icons.groups_rounded,
        label: context.t(vi: 'So tài', en: 'Versus'),
        color: const Color(0xFF10B981),
        route: AppRoutes.multiplayer,
        availability: FeatureAvailability.requiresBackend,
      ),
      _FeatureShortcutData(
        icon: Icons.spa_rounded,
        label: context.t(vi: 'Thư giãn', en: 'Relax'),
        color: const Color(0xFF14B8A6),
        route: AppRoutes.mindfulBreak,
        availability: FeatureAvailability.beta,
      ),
      _FeatureShortcutData(
        icon: Icons.pets_rounded,
        label: context.t(vi: 'Linh vật', en: 'Mascot'),
        color: const Color(0xFF8B5CF6),
        route: AppRoutes.mascotSelection,
        availability: FeatureAvailability.beta,
      ),
    ];

    return ZenCard(
      radius: GrowMateLayout.cardRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t(vi: 'Lối tắt nhanh', en: 'Quick shortcuts'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              vi: 'Giữ Home gọn nhẹ. Chỉ hiện các tác vụ hay dùng nhất.',
              en: 'Keep Home calm. Show only your most-used actions first.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Wrap(
            spacing: GrowMateLayout.space8,
            runSpacing: GrowMateLayout.space8,
            children: [
              for (final item in primary)
                _FeatureShortcutChip(data: item, emphasized: true),
            ],
          ),
          const SizedBox(height: GrowMateLayout.space8),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: colors.onSurfaceVariant,
              collapsedIconColor: colors.onSurfaceVariant,
              title: Text(
                context.t(vi: 'Khám phá thêm', en: 'Explore more'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              // Đã xóa subtitle nhỏ dưới tên mục công thức theo yêu cầu
              children: [
                const SizedBox(height: GrowMateLayout.space8),
                Wrap(
                  spacing: GrowMateLayout.space8,
                  runSpacing: GrowMateLayout.space8,
                  children: [
                    for (final item in secondary)
                      _FeatureShortcutChip(data: item),
                  ],
                ),
                const SizedBox(height: GrowMateLayout.space12),
                _MoodCheckAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureShortcutData {
  const _FeatureShortcutData({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.availability = FeatureAvailability.server,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final FeatureAvailability availability;
}

class _FeatureShortcutChip extends StatelessWidget {
  const _FeatureShortcutChip({required this.data, this.emphasized = false});

  final _FeatureShortcutData data;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = emphasized
        ? data.color.withValues(alpha: 0.12)
        : colors.surfaceContainerLow;
    final borderColor = emphasized
        ? data.color.withValues(alpha: 0.3)
        : colors.outlineVariant.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.push(data.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 18, color: data.color),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              // FeatureAvailabilityBadge removed as per UI cleanup request
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCheckAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        alignment: Alignment.centerLeft,
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      onPressed: () async {
        final mood = await MoodCheckDialog.show(context);
        if (mood != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.t(
                  vi: 'Da ghi nhan: ${mood.emoji} ${mood.viLabel}',
                  en: 'Recorded: ${mood.emoji} ${mood.enLabel}',
                ),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      icon: Icon(
        Icons.mood_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        context.t(vi: 'Ghi cảm xúc hôm nay', en: 'Log today\'s mood'),
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
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

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey<String>('ai-hero-empty'),
      width: double.infinity,
      padding: GrowMateLayout.cardPaddingAi,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusLg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: GrowMateLayout.space8),
              Text(
                context.t(vi: 'AI đang chờ bạn', en: 'AI is waiting for you'),
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
              vi: 'Hoàn thành phiên đầu tiên để AI phân tích tiềm năng của bạn!',
              en: 'Complete your first session so AI can analyze your potential!',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space16),
          ZenButton(
            label: context.t(
              vi: 'Làm phiên đầu tiên',
              en: 'Complete first session',
            ),
            onPressed: () => context.push(AppRoutes.quiz),
          ),
        ],
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

/// Floating Chat AI button displayed above the bottom navigation bar.
class _ChatFab extends StatefulWidget {
  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        String? name;
        if (snap.hasData) name = snap.data!.getString('selected_mascot');
        final MascotId? sel = name == null
            ? null
            : MascotId.values.firstWhere(
                (e) => e.name == name,
                orElse: () => MascotId.cat,
              );
        final child = sel != null
            ? Text(
                Mascot.all.firstWhere((m) => m.id == sel).emoji,
                style: const TextStyle(fontSize: 22),
              )
            : const Icon(Icons.smart_toy_rounded, size: 26);

        return FloatingActionButton(
          onPressed: () => context.push(AppRoutes.chat),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 4,
          tooltip: 'Chat AI',
          child: child,
        );
      },
    );
  }
}
