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
              subtitle: 'AI tổng hợp điểm mạnh và lỗ hổng cần xử lý tiếp theo',
              bottomSpacing: 14,
            ),
            if (progress.isEmpty)
              const _ProgressEmptyState()
            else ...[
              _ProgressOverview(progress: progress),
              const SizedBox(height: 14),
              _StrengthSection(progress: progress),
              const SizedBox(height: 14),
              _ImproveSection(progress: progress),
              const SizedBox(height: 14),
              _FocusTrendSection(progress: progress),
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

    return InsightCard(
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
                  label: 'Khái niệm đã fix',
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

    return InsightCard(
      title: 'Bạn đang mạnh ở',
      subtitle: 'Tiếp tục duy trì đà này',
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
                    (entry) => ProgressBarItem(
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

    return InsightCard(
      title: 'Cần cải thiện',
      subtitle: 'Ưu tiên xử lý trong phiên kế tiếp',
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
                    (entry) => ProgressBarItem(
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

class _FocusTrendSection extends StatelessWidget {
  const _FocusTrendSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: 'Xu hướng tập trung',
      subtitle: '3 phiên gần nhất',
      delayMs: 160,
      child: Column(
        children: progress.moodTrend
            .asMap()
            .entries
            .map(
              (entry) => ProgressBarItem(
                label: entry.value.sessionLabel,
                value: entry.value.focusScore / 4,
                trailingLabel:
                    '${(entry.value.focusScore / 4 * 100).toStringAsFixed(0)}%',
                color: GrowMateColors.primary,
                delayMs: 180 + entry.key * 30,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: 'Chưa có dữ liệu tiến trình',
      subtitle: 'Bắt đầu một phiên học để AI tổng hợp năng lực',
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
              'Khi hoàn tất bài đầu tiên, bạn sẽ thấy phân tích mạnh/yếu ngay tại đây.',
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
