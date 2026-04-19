import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/models/feature_availability.dart';
import '../../../../shared/widgets/feature_availability_banner.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../achievement_i18n.dart';
import '../../data/models/achievement_badge.dart';
import '../../data/repositories/achievement_repository.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleSpacing: 0,
        title: Text(
          context.t(vi: 'Thành tựu', en: 'Achievements'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
      body: ZenPageContainer(
        includeBottomSafeArea: true,
        child: Column(
          children: [
            Text(
              context.t(
                vi: 'Ghi nhận nỗ lực tích cực, không tạo áp lực điểm số',
                en: 'Celebrate positive effort without score pressure',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GrowMateLayout.space12),
            FeatureAvailabilityBanner(
              availability: FeatureAvailability.beta,
              message: context.t(
                vi: 'Achievements hien duoc tinh local. Hay de man nay ngoai luong demo backend chinh.',
                en: 'Achievements are currently computed locally. Keep this screen outside the main backend demo flow.',
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            Expanded(
              child: StreamBuilder<List<AchievementBadge>>(
                stream: AchievementRepository.instance.watchUnlocked(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: GrowMateLayout.space12),
                          Text(
                            context.t(
                              vi: 'Không tải được thành tựu',
                              en: 'Unable to load achievements',
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: GrowMateLayout.space12),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(context.t(vi: 'Thử lại', en: 'Retry')),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final unlocked = snapshot.data ?? const <AchievementBadge>[];

                  return ListView(
                    padding: const EdgeInsets.only(
                      bottom: GrowMateLayout.sectionGap,
                    ),
                    children: [
                      _UnlockedSection(badges: unlocked),
                      const SizedBox(height: GrowMateLayout.sectionGapLg),
                      const _ComingSoonSection(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedSection extends StatelessWidget {
  const _UnlockedSection({required this.badges});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              context.t(
                vi: 'Đã mở khóa (${badges.length})',
                en: 'Unlocked (${badges.length})',
              ),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: GrowMateLayout.itemGapSm),
        if (badges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                Text(
                  context.t(
                    vi: 'Hoàn thành vài phiên học để mở khóa huy hiệu đầu tiên!',
                    en: 'Complete a few study sessions to unlock your first badge!',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...badges.map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconForBadge(badge.iconKey),
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizedBadgeTitle(context, badge),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizedBadgeDescription(context, badge),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (badge.unlockedAt.isAfter(DateTime(2000))) ...[
                            const SizedBox(height: 4),
                            Text(
                              context.t(
                                vi: 'Mở khóa ${_formatDate(badge.unlockedAt)}',
                                en: 'Unlocked ${_formatDate(badge.unlockedAt)}',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconForBadge(String key) {
    return switch (key) {
      'rocket' => Icons.rocket_launch_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'spa' => Icons.spa_rounded,
      'psychology_alt' => Icons.psychology_alt_rounded,
      'calendar_month' => Icons.calendar_month_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              context.t(vi: 'Lộ trình tiếp theo', en: 'Next up'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: GrowMateLayout.itemGapSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                  vi: '🏆 Bảng xếp hạng & thử thách tuần',
                  en: '🏆 Leaderboard & weekly challenges',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t(
                  vi: '📊 Thống kê chi tiết & heatmap học tập',
                  en: '📊 Detailed stats & study heatmap',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
