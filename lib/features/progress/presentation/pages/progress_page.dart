import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/premium_sections.dart';
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
            const SizedBox(height: GrowMateLayout.sectionGap),
            Text(
              'Tiến trình tuần này',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: GrowMateLayout.space8),
            Text(
              'Tập trung vào chủ đề quan trọng nhất để tăng tốc trong phiên tiếp theo.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: GrowMateColors.textSecondary,
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            if (progress.isEmpty)
              const _ProgressEmptyState()
            else ...[
              _SummarySection(progress: progress),
              const SizedBox(height: GrowMateLayout.sectionGapLg),
              _WeaknessSection(progress: progress),
            ],
            const SizedBox(height: GrowMateLayout.sectionGap),
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

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final ratio = _parseWeeklyRatio(progress.weeklyConsistency);
    final percentage = (ratio * 100).round();

    return Section(
      title: 'Tóm tắt',
      subtitle: _weeklySummaryLabel(progress.weeklyConsistency),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GrowMateLayout.contentGap),
            decoration: BoxDecoration(
              color: GrowMateColors.backgroundSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weeklySummaryLabel(progress.weeklyConsistency),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                Row(
                  children: [
                    Text(
                      'Tóm tắt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GrowMateColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GrowMateColors.textSecondary,
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
                    backgroundColor: GrowMateColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2DA5A8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          Text(
            progress.learningRhythm,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaknessSection extends StatelessWidget {
  const _WeaknessSection({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final strengths =
        progress.masteryMap
            .where((item) => item.score >= 3.0)
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));

    final gaps =
        progress.masteryMap
            .where((item) => item.score < 3.0)
            .toList(growable: false)
          ..sort((a, b) => a.score.compareTo(b.score));

    final weakest = gaps.isEmpty ? null : gaps.first;
    final recommendation = weakest == null
        ? 'Giữ nhịp hiện tại và thêm một bài nâng cao trong phiên tới.'
        : 'Khuyến nghị AI: luyện trọng tâm ${weakest.topic} trong 15 phút, sau đó kiểm tra lại bằng 3 câu tính giờ.';

    return Section(
      title: 'Điểm mạnh và điểm yếu',
      subtitle: 'Tập trung vào 1 chủ đề yếu để tăng độ tự tin nhanh hơn',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (strengths.isNotEmpty) ...[
            Text(
              'Điểm mạnh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: GrowMateColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GrowMateLayout.space12),
            ...strengths
                .take(2)
                .toList(growable: false)
                .asMap()
                .entries
                .map(
                  (entry) => ProgressBar(
                    label: entry.value.topic,
                    value: entry.value.score / 4,
                    trailing: '${((entry.value.score / 4) * 100).round()}%',
                    caption: entry.value.statusLabel,
                    color: GrowMateColors.success,
                    delayMs: 70 + entry.key * 45,
                  ),
                ),
            const SizedBox(height: GrowMateLayout.space8),
          ],
          Text(
            'Điểm yếu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: GrowMateColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          if (gaps.isEmpty)
            Text(
              'Tuyệt vời, hiện chưa có lỗ hổng cần ưu tiên.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
              ),
            )
          else
            ...gaps
                .take(3)
                .toList(growable: false)
                .asMap()
                .entries
                .map(
                  (entry) => ProgressBar(
                    label: entry.value.topic,
                    value: entry.value.score / 4,
                    trailing: '${((entry.value.score / 4) * 100).round()}%',
                    caption: 'Cần review lại',
                    color: GrowMateColors.warningSoft,
                    delayMs: 80 + entry.key * 45,
                  ),
                ),
          const SizedBox(height: GrowMateLayout.space8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GrowMateLayout.contentGap),
            decoration: BoxDecoration(
              color: GrowMateColors.backgroundSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: GrowMateColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Section(
      title: 'Chưa có dữ liệu tiến trình',
      subtitle: 'Hoàn tất một phiên để AI bắt đầu bản đồ hóa năng lực',
      child: Row(
        children: [
          Icon(Icons.timeline_rounded, color: GrowMateColors.primary),
          SizedBox(width: GrowMateLayout.space12),
          Expanded(
            child: Text(
              'Khi bạn hoàn thành bài đầu tiên, hệ thống sẽ tự động hiển thị điểm mạnh, điểm yếu và lộ trình cập nhật.',
              style: TextStyle(color: GrowMateColors.textSecondary),
            ),
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

String _weeklySummaryLabel(String value) {
  final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(value);
  if (match == null) {
    return value;
  }

  final done = match.group(1) ?? '0';
  final total = match.group(2) ?? '0';
  return '$done/$total buổi đã hoàn thành tuần này';
}
