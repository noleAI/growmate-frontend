import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/badge_unlock_popup.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../achievement/data/models/achievement_badge.dart';
import '../../../achievement/data/repositories/achievement_repository.dart';
import '../../../achievement/presentation/achievement_i18n.dart';
import '../../../notification/data/repositories/notification_repository.dart';
import '../../../quiz/data/repositories/quiz_api_repository.dart';
import '../../../review/data/repositories/spaced_repetition_repository.dart';
import '../../data/models/session_history_entry.dart';
import '../../data/repositories/session_history_repository.dart';

class SessionCompletePage extends StatefulWidget {
  const SessionCompletePage({
    super.key,
    required this.queryParameters,
    required this.sessionHistoryRepository,
    required this.notificationRepository,
    this.quizApiRepository,
  });

  final Map<String, String> queryParameters;
  final SessionHistoryRepository sessionHistoryRepository;
  final NotificationRepository notificationRepository;
  final QuizApiRepository? quizApiRepository;

  @override
  State<SessionCompletePage> createState() => _SessionCompletePageState();
}

class _SessionCompletePageState extends State<SessionCompletePage> {
  late Future<_CompletionPayload> _payloadFuture;
  bool _completionStarted = false;
  bool _badgePopupShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_completionStarted) {
      return;
    }
    _completionStarted = true;
    _payloadFuture = _recordCompletion(isEnglish: context.isEnglish)
      ..then((payload) {
        if (payload.newBadges.isNotEmpty && mounted && !_badgePopupShown) {
          _badgePopupShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              BadgeUnlockPopup.showAll(context, payload.newBadges);
            }
          });
        }
      });
  }

  Future<_CompletionPayload> _recordCompletion({
    required bool isEnglish,
  }) async {
    final params = widget.queryParameters;
    final submissionId = params['submissionId']?.trim() ?? '';
    final diagnosisId = params['diagnosisId']?.trim() ?? '';
    var topic = params['topic']?.trim() ?? '';
    var nextAction = params['nextAction']?.trim() ?? '';

    final sourceKey = (submissionId.isEmpty && diagnosisId.isEmpty)
        ? 'manual_${DateTime.now().millisecondsSinceEpoch}'
        : 'submission:$submissionId|diagnosis:$diagnosisId';
    var mode = (params['mode'] ?? 'academic').toLowerCase();

    var durationMinutes = int.tryParse(params['duration'] ?? '') ?? 0;
    var focusScore = double.tryParse(params['focus'] ?? '') ?? 0.0;
    var confidenceScore = double.tryParse(params['confidence'] ?? '') ?? 0.0;

    final shouldHydrateFromServer =
        submissionId.isNotEmpty &&
        (topic.isEmpty ||
            nextAction.isEmpty ||
            durationMinutes <= 0 ||
            focusScore <= 0 ||
            confidenceScore <= 0);

    if (widget.quizApiRepository != null && shouldHydrateFromServer) {
      try {
        final result = await widget.quizApiRepository!.getSessionResult(
          sessionId: submissionId,
        );
        final accuracy = (result.summary.accuracyPercent / 100)
            .clamp(0.0, 1.0)
            .toDouble();

        if (topic.isEmpty) {
          topic = _deriveTopicFromSessionId(
            sessionId: result.sessionId.isNotEmpty
                ? result.sessionId
                : submissionId,
          );
        }

        if (nextAction.isEmpty) {
          nextAction = _deriveNextActionFromConfidence(
            confidence: accuracy,
            isEnglish: isEnglish,
          );
        }

        if (durationMinutes <= 0) {
          durationMinutes = _deriveDurationMinutes(
            answeredCount: result.summary.answeredCount,
          );
        }

        if (focusScore <= 0) {
          focusScore = (accuracy * 4).clamp(0.0, 4.0).toDouble();
        }

        if (confidenceScore <= 0) {
          confidenceScore = accuracy;
        }

        if (mode == 'academic' &&
            result.sessionStatus.toLowerCase() == 'abandoned') {
          mode = 'recovery';
        }
      } catch (_) {
        // Keep original query-driven payload as graceful fallback.
      }
    }

    final entry = await widget.sessionHistoryRepository.upsertCompletedSession(
      sourceKey: sourceKey,
      topic: topic,
      mode: mode,
      durationMinutes: durationMinutes,
      focusScore: focusScore,
      confidenceScore: confidenceScore,
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
        reason: mode == 'recovery'
            ? (isEnglish ? 'fatigue' : 'mệt mỏi')
            : (isEnglish ? 'focus drop' : 'focus giảm'),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: context.t(vi: 'Về trang chủ', en: 'Go home'),
                    onPressed: () {
                      context.go(AppRoutes.home);
                    },
                    padding: EdgeInsets.all(12),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final heroHeight = (availableHeight * 0.35).clamp(
                      180.0,
                      320.0,
                    );
                    return SizedBox(
                      height: heroHeight,
                      child: ZenCard(
                        radius: 36,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.85,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 142,
                            height: 142,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.7,
                                  ),
                                  theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.55,
                                  ),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.energy_savings_leaf_rounded,
                              size: 78,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: GrowMateLayout.space16),
                Text(
                  context.t(
                    vi: 'Hôm nay bạn học\nrất ổn ✨',
                    en: 'You studied\nvery well today ✨',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.tertiaryContainer,
                      border: Border.all(
                        color: theme.colorScheme.tertiary.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: Text(
                      entry == null
                          ? context.t(
                              vi: 'ĐANG LƯU KẾT QUẢ...',
                              en: 'SAVING RESULTS...',
                            )
                          : context.t(
                              vi: 'ĐÃ LƯU TIMELINE PHIÊN HỌC',
                              en: 'SESSION TIMELINE SAVED',
                            ),
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space16),
                ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoundedInfoIcon(
                        icon: Icons.psychology_alt_rounded,
                        color: theme.colorScheme.tertiaryContainer,
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
                                    _completionTopicText(context, entry?.topic),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _suggestionText(context, entry?.nextAction),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoundedInfoIcon(
                        icon: Icons.favorite_rounded,
                        color: theme.colorScheme.surfaceContainerHigh,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.t(
                            vi: '"Cảm ơn bạn đã đồng hành cùng mình hôm nay nha!"',
                            en: '"Thank you for learning with me today!"',
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.48,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: GrowMateLayout.space12),
                  ZenCard(
                    radius: GrowMateLayout.cardRadius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t(
                            vi: 'Huy hiệu mới mở khóa',
                            en: 'Newly unlocked badges',
                          ),
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
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${localizedBadgeTitle(context, badge)} · ${localizedBadgeDescription(context, badge)}',
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
                const SizedBox(height: GrowMateLayout.sectionGap),
                ZenButton(
                  label: context.t(
                    vi: 'Kết thúc phiên học',
                    en: 'Finish session',
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                ZenButton(
                  label: context.t(
                    vi: 'Nghỉ thở 90 giây',
                    en: 'Mindful Break 90s',
                  ),
                  variant: ZenButtonVariant.secondary,
                  onPressed: () {
                    context.go(AppRoutes.mindfulBreak);
                  },
                ),
                const SizedBox(height: GrowMateLayout.space12),
                ZenButton(
                  label: context.t(
                    vi: 'Xem timeline tuần',
                    en: 'View weekly timeline',
                  ),
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
    );
  }

  String _completionTopicText(BuildContext context, String? topic) {
    final trimmed = topic?.trim() ?? '';
    if (context.isEnglish) {
      if (trimmed.isEmpty) {
        return 'You just completed this learning session.';
      }
      return 'You just completed:\n$trimmed';
    }

    if (trimmed.isEmpty) {
      return 'Bạn vừa hoàn thành phiên học này.';
    }
    return 'Bạn vừa hoàn thành:\n$trimmed';
  }

  String _suggestionText(BuildContext context, String? nextAction) {
    final trimmed = nextAction?.trim() ?? '';
    if (context.isEnglish) {
      if (trimmed.isEmpty) {
        return 'Suggestion for tomorrow: Continue with the next recommended step.';
      }
      return 'Suggestion for tomorrow: $trimmed';
    }

    if (trimmed.isEmpty) {
      return 'Gợi ý ngày mai: Tiếp tục theo bước được gợi ý tiếp theo';
    }
    return 'Gợi ý ngày mai: $trimmed';
  }
}

String _deriveTopicFromSessionId({required String sessionId}) {
  final suffix = sessionId.length > 8
      ? sessionId.substring(sessionId.length - 8)
      : sessionId;
  return 'Phiên quiz #$suffix';
}

String _deriveNextActionFromConfidence({
  required double confidence,
  required bool isEnglish,
}) {
  if (confidence >= 0.85) {
    return isEnglish
        ? 'Increase difficulty slightly in your next session.'
        : 'Tăng nhẹ độ khó ở phiên kế tiếp.';
  }
  if (confidence >= 0.6) {
    return isEnglish
        ? 'Review incorrect questions and solve 2 similar ones.'
        : 'Ôn lại nhóm câu sai và làm thêm 2 câu tương tự.';
  }
  return isEnglish
      ? 'Revisit core theory before moving on.'
      : 'Ôn lại lý thuyết cốt lõi trước khi tiếp tục.';
}

int _deriveDurationMinutes({required int answeredCount}) {
  final estimated = answeredCount <= 0 ? 8 : answeredCount * 2;
  return estimated.clamp(5, 120).toInt();
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
    this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
        size: 28,
      ),
    );
  }
}
