import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/mock_user_progress_generator.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key}) : _profile = null, _forceEmptyState = false;

  final UserProfile? _profile;
  final bool _forceEmptyState;

  @override
  Widget build(BuildContext context) {
    return ProgressScreen(profile: _profile, forceEmptyState: _forceEmptyState);
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.profile, this.forceEmptyState = false});

  final UserProfile? profile;
  final bool forceEmptyState;

  @override
  Widget build(BuildContext context) {
    final progress = MockUserProgressGenerator.fromUserProfile(
      profile,
      forceEmptyState: forceEmptyState,
    );

    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const GrowMateTopAppBar(),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Tiến trình học tập',
              subtitle:
                  'AI liên tục tổng hợp điểm mạnh, điểm yếu và bước tiếp theo',
              bottomSpacing: 14,
            ),
            if (progress.isEmpty)
              const _ProgressEmptyState()
            else ...[
              _ProgressOverview(progress: progress),
              const SizedBox(height: 14),
              _AiInsightSection(progress: progress),
              const SizedBox(height: 14),
              _StrengthSection(progress: progress),
              const SizedBox(height: 14),
              _ImproveSection(progress: progress),
              const SizedBox(height: 14),
              _RecommendationSection(progress: progress),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.progress,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiInsightCard(
      title: 'Tổng quan hôm nay',
      subtitle: progress.weeklyConsistency,
      delayMs: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Khái niệm đã ổn định',
                  value: '${progress.fixedConcepts.length}',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _StatTile(
                  label: 'Mục tiêu tuần',
                  value: '6 phiên',
                  icon: Icons.track_changes_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            progress.learningRhythm,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightSection extends StatelessWidget {
  const _AiInsightSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final sortedByLowest = progress.masteryMap.toList(growable: false)
      ..sort((a, b) => a.score.compareTo(b.score));

    final weakestTopic = sortedByLowest.isEmpty
        ? null
        : sortedByLowest.first.topic;
    final insightText = weakestTopic == null
        ? 'Nhận định AI: Nhịp học hiện tại đang cân bằng. Hãy giữ đà này.'
        : 'Nhận định AI: Bạn đang gặp khó ổn định ở các bài tốc độ phần $weakestTopic.';

    return AiInsightCard(
      title: 'Nhận định AI',
      subtitle: 'Tổng hợp từ các bài bạn vừa hoàn thành',
      delayMs: 65,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: GrowMateColors.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: GrowMateColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insightText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: GrowMateColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final strengths =
        progress.masteryMap
            .where((item) => item.score >= 3.0)
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));

    return AiInsightCard(
      title: 'Điểm mạnh',
      subtitle: 'Tận dụng để tăng tốc các chủ đề khó hơn',
      delayMs: 80,
      child: strengths.isEmpty
          ? const _EmptyHint(
              label:
                  'Chưa có chủ đề vượt ngưỡng mạnh. Hãy hoàn thành thêm 1 phiên luyện.',
            )
          : Column(
              children: strengths
                  .asMap()
                  .entries
                  .map(
                    (entry) => ProgressItem(
                      label: entry.value.topic,
                      value: entry.value.score / 4,
                      trailingLabel:
                          '${(entry.value.score / 4 * 100).toStringAsFixed(0)}%',
                      caption: 'Trạng thái: ${entry.value.statusLabel}',
                      color: GrowMateColors.success,
                      delayMs: 120 + entry.key * 35,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ImproveSection extends StatelessWidget {
  const _ImproveSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final gaps =
        progress.masteryMap
            .where((item) => item.score < 3.0)
            .toList(growable: false)
          ..sort((a, b) => a.score.compareTo(b.score));

    return AiInsightCard(
      title: 'Điểm yếu',
      subtitle: 'Đây là các điểm đang giới hạn tốc độ và độ tự tin',
      delayMs: 120,
      child: gaps.isEmpty
          ? const _EmptyHint(
              label: 'Tuyệt vời, hiện chưa có lỗ hổng cần ưu tiên.',
            )
          : Column(
              children: gaps
                  .asMap()
                  .entries
                  .map(
                    (entry) => ProgressItem(
                      label: entry.value.topic,
                      value: entry.value.score / 4,
                      trailingLabel:
                          '${(entry.value.score / 4 * 100).toStringAsFixed(0)}%',
                      caption: 'Khuyến nghị: luyện 4-6 câu mức cơ bản',
                      color: GrowMateColors.warningSoft,
                      delayMs: 140 + entry.key * 35,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final sortedByLowest = progress.masteryMap.toList(growable: false)
      ..sort((a, b) => a.score.compareTo(b.score));
    final weakest = sortedByLowest.isEmpty ? null : sortedByLowest.first;
    final recommendationText = weakest == null
        ? 'Giữ nhịp hiện tại và thêm 1 thử thách nâng cao ở phiên tiếp theo.'
        : 'Luyện trọng tâm 15 phút cho ${weakest.topic}, rồi kiểm tra lại độ chính xác với 3 câu tính giờ.';

    return AiInsightCard(
      title: 'Khuyến nghị',
      subtitle: 'Lộ trình của bạn đã được AI điều chỉnh',
      delayMs: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: progress.moodTrend.isEmpty
            ? <Widget>[
                Text(
                  recommendationText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : <Widget>[
                Text(
                  recommendationText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Xu hướng tập trung gần đây',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...progress.moodTrend.asMap().entries.map(
                  (entry) => ProgressItem(
                    label: entry.value.sessionLabel,
                    value: entry.value.focusScore / 4,
                    trailingLabel:
                        '${(entry.value.focusScore / 4 * 100).toStringAsFixed(0)}%',
                    color: GrowMateColors.primary,
                    delayMs: 180 + entry.key * 30,
                  ),
                ),
                if (progress.fixedConcepts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Các khái niệm đã ổn định',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GrowMateColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: progress.fixedConcepts
                        .map(
                          (concept) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: GrowMateColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              concept,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: GrowMateColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
      ),
    );
  }
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    return AiInsightCard(
      title: 'Chưa có dữ liệu tiến trình',
      subtitle: 'Hoàn thành 1 phiên học để AI bắt đầu lập bản đồ năng lực',
      delayMs: 30,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GrowMateColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timeline_rounded,
              color: GrowMateColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Khi bạn hoàn tất bài đầu tiên, nhận định AI sẽ tự động hiển thị tại đây.',
              style: TextStyle(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GrowMateColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GrowMateColors.textSecondary,
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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: GrowMateColors.textSecondary),
    );
  }
}
