import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../achievement/data/models/achievement_badge.dart';
import '../../../achievement/data/repositories/achievement_repository.dart';
import '../../../notification/data/repositories/notification_repository.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../../data/models/session_history_entry.dart';
import '../../data/repositories/session_history_repository.dart';

class SessionCompletePage extends StatefulWidget {
  const SessionCompletePage({
    super.key,
    required this.queryParameters,
    required this.sessionHistoryRepository,
    required this.notificationRepository,
  });

  final Map<String, String> queryParameters;
  final SessionHistoryRepository sessionHistoryRepository;
  final NotificationRepository notificationRepository;

  @override
  State<SessionCompletePage> createState() => _SessionCompletePageState();
}

class _SessionCompletePageState extends State<SessionCompletePage> {
  late final Future<_CompletionPayload> _payloadFuture;

  @override
  void initState() {
    super.initState();
    _payloadFuture = _recordCompletion();
  }

  Future<_CompletionPayload> _recordCompletion() async {
    final params = widget.queryParameters;
    final submissionId = params['submissionId']?.trim() ?? '';
    final diagnosisId = params['diagnosisId']?.trim() ?? '';
    final topic = (params['topic']?.trim().isNotEmpty ?? false)
        ? params['topic']!.trim()
        : 'Review Đạo hàm';
    final nextAction = (params['nextAction']?.trim().isNotEmpty ?? false)
        ? params['nextAction']!.trim()
        : 'Ôn 3 câu nhẹ trước khi vào bài mới';

    final sourceKey = (submissionId.isEmpty && diagnosisId.isEmpty)
        ? 'manual_${DateTime.now().millisecondsSinceEpoch}'
        : 'submission:$submissionId|diagnosis:$diagnosisId';
    final mode = (params['mode'] ?? 'academic').toLowerCase();

    final entry = await widget.sessionHistoryRepository.upsertCompletedSession(
      sourceKey: sourceKey,
      topic: topic,
      mode: mode,
      durationMinutes: 12,
      focusScore: mode == 'recovery' ? 2.8 : 3.4,
      confidenceScore: mode == 'recovery' ? 0.72 : 0.83,
      nextAction: nextAction,
    );

    await SpacedRepetitionRepository.instance.registerStudySession(
      topic: entry.topic,
      focusScore: entry.focusScore,
      sourceKey: sourceKey,
      completedAt: entry.completedAt,
    );

    final history = await widget.sessionHistoryRepository.getHistory();
    final newBadges = await AchievementRepository.instance.evaluateMilestones(
      history: history,
    );

    for (final badge in newBadges) {
      await widget.notificationRepository.pushBadgeUnlockedEvent(
        badgeId: badge.id,
        badgeTitle: badge.title,
      );
    }

    if (mode == 'recovery' || entry.focusScore < 3.0) {
      await widget.notificationRepository.pushMindfulBreakEvent(
        sourceKey: sourceKey,
        reason: mode == 'recovery' ? 'mệt mỏi' : 'focus giảm',
      );
    }

    await widget.notificationRepository.pushSessionCompletedEvent(
      topic: entry.topic,
      nextAction: entry.nextAction,
      sourceKey: sourceKey,
    );

    await widget.notificationRepository.ensureSpacedReviewReminderIfNeeded();

    return _CompletionPayload(entry: entry, newBadges: newBadges);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: FutureBuilder<_CompletionPayload>(
          future: _payloadFuture,
          builder: (context, snapshot) {
            final payload = snapshot.data;
            final entry = payload?.entry;
            final newBadges = payload?.newBadges ?? const <AchievementBadge>[];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return ListView(
              children: [
                const GrowMateTopAppBar(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 292,
                  child: ZenCard(
                    radius: 36,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEFF7ED), Color(0xFFE5F0EA)],
                    ),
                    child: Center(
                      child: Container(
                        width: 142,
                        height: 142,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD7E9CF), Color(0xFFC1DDC1)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: GrowMateColors.shadowSoft,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.energy_savings_leaf_rounded,
                          size: 78,
                          color: GrowMateColors.success,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Hôm nay bạn học\nrất ổn ✨',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: GrowMateColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: GrowMateColors.tertiaryContainer,
                      border: Border.all(
                        color: GrowMateColors.success.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      entry == null
                          ? 'ĐANG LƯU KẾT QUẢ...'
                          : 'ĐÃ LƯU TIMELINE PHIÊN HỌC',
                      style: const TextStyle(
                        color: GrowMateColors.success,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ZenCard(
                  radius: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RoundedInfoIcon(
                        icon: Icons.psychology_alt_rounded,
                        color: GrowMateColors.tertiaryContainer,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: LinearProgressIndicator(minHeight: 4),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bạn vừa hoàn thành:\n${entry?.topic ?? 'Review Đạo hàm'}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: GrowMateColors.textPrimary,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gợi ý ngày mai: ${entry?.nextAction ?? 'Ôn 3 câu nhẹ trước khi vào bài mới'}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: GrowMateColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ZenCard(
                  radius: 30,
                  color: const Color(0xFFEAF0EE),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RoundedInfoIcon(
                        icon: Icons.favorite_rounded,
                        color: Color(0xFFD4E2DF),
                        iconColor: GrowMateColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '"Cảm ơn bạn đã đồng hành cùng mình hôm nay nha!"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: GrowMateColors.textSecondary,
                            height: 1.48,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ZenCard(
                    radius: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Huy hiệu mới mở khóa',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...newBadges.map(
                          (badge) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: GrowMateColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${badge.title} · ${badge.description}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ZenButton(
                  label: 'Kết thúc phiên học',
                  onPressed: () => context.go(AppRoutes.home),
                ),
                const SizedBox(height: 14),
                ZenButton(
                  label: 'Mindful Break 90 giây',
                  variant: ZenButtonVariant.secondary,
                  onPressed: () {
                    context.go(AppRoutes.mindfulBreak);
                  },
                ),
                const SizedBox(height: 14),
                ZenButton(
                  label: 'Xem timeline tuần',
                  variant: ZenButtonVariant.secondary,
                  onPressed: () {
                    context.go('${AppRoutes.progress}?focus=timeline');
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.today,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _CompletionPayload {
  const _CompletionPayload({required this.entry, required this.newBadges});

  final SessionHistoryEntry entry;
  final List<AchievementBadge> newBadges;
}

class _RoundedInfoIcon extends StatelessWidget {
  const _RoundedInfoIcon({
    required this.icon,
    required this.color,
    this.iconColor = GrowMateColors.success,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
