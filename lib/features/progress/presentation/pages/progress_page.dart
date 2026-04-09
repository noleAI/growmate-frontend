import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_card.dart';
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
    final theme = Theme.of(context);
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
            const SizedBox(height: 16),
            Text(
              'Tiến trình',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 34,
                color: GrowMateColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mình lưu lại nhịp học và tinh thần của bạn để gợi ý nhẹ nhàng hơn theo thời gian.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            if (progress.isEmpty)
              const _ProgressEmptyState()
            else ...[
              _LearningRhythmCard(progress: progress),
              const SizedBox(height: 14),
              _MasteryCard(progress: progress),
              const SizedBox(height: 14),
              _MoodTrendCard(progress: progress),
            ],
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

class _LearningRhythmCard extends StatelessWidget {
  const _LearningRhythmCard({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F8EF), Color(0xFFEAF0E5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhịp học tuần này',
            style: theme.textTheme.titleLarge?.copyWith(
              color: GrowMateColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress.learningRhythm,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _RhythmChip(label: 'T2', active: true),
              _RhythmChip(label: 'T3', active: true),
              _RhythmChip(label: 'T4', active: false),
              _RhythmChip(label: 'T5', active: true),
              _RhythmChip(label: 'T6', active: true),
              _RhythmChip(label: 'T7', active: false),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            progress.weeklyConsistency,
            style: theme.textTheme.bodySmall?.copyWith(
              color: GrowMateColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      color: Colors.white.withValues(alpha: 0.86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lỗ hổng đã lấp',
            style: theme.textTheme.titleLarge?.copyWith(
              color: GrowMateColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBackgroundColor: Colors.transparent,
                radarBorderData: BorderSide(
                  color: GrowMateColors.primary.withValues(alpha: 0.16),
                ),
                tickBorderData: BorderSide(
                  color: GrowMateColors.primary.withValues(alpha: 0.08),
                ),
                gridBorderData: BorderSide(
                  color: GrowMateColors.primary.withValues(alpha: 0.08),
                ),
                titleTextStyle: theme.textTheme.bodySmall?.copyWith(
                  color: GrowMateColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                getTitle: (index, angle) {
                  final topic = progress.masteryMap[index].topic;
                  return RadarChartTitle(text: topic, angle: angle);
                },
                dataSets: [
                  RadarDataSet(
                    dataEntries: progress.masteryMap
                        .map((item) => RadarEntry(value: item.score))
                        .toList(growable: false),
                    fillColor: GrowMateColors.primary.withValues(alpha: 0.2),
                    borderColor: GrowMateColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                tickCount: 4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...progress.masteryMap.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record_rounded,
                    size: 10,
                    color: GrowMateColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.topic}: ${item.statusLabel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: GrowMateColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Những phần bạn đã xử lý tốt gần đây:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GrowMateColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  const _MoodTrendCard({required this.progress});

  final UserProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      color: const Color(0xFFF2F5EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sức khỏe tinh thần',
            style: theme.textTheme.titleLarge?.copyWith(
              color: GrowMateColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Xu hướng mức tập trung trong 3 phiên gần nhất',
            style: theme.textTheme.bodySmall?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (progress.moodTrend.length - 1).toDouble(),
                minY: 1,
                maxY: 4,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: GrowMateColors.primary.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final label = switch (value.toInt()) {
                          1 => 'Hơi mệt',
                          2 => 'Ổn',
                          3 => 'Tập trung',
                          4 => 'Rất tốt',
                          _ => '',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: GrowMateColors.textSecondary,
                            ),
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final rounded = value.roundToDouble();
                        if ((value - rounded).abs() > 0.001) {
                          return const SizedBox.shrink();
                        }

                        final index = rounded.toInt();
                        if (index < 0 || index >= progress.moodTrend.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'P${index + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: GrowMateColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List<FlSpot>.generate(progress.moodTrend.length, (
                      index,
                    ) {
                      return FlSpot(
                        index.toDouble(),
                        progress.moodTrend[index].focusScore,
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: const Color(0xFF6A8F77),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF6A8F77),
                          strokeWidth: 1.2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF9FC3AE).withValues(alpha: 0.25),
                    ),
                  ),
                ],
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
    final theme = Theme.of(context);

    return ZenCard(
      radius: 28,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5F8EE), Color(0xFFF2EFE3)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFECE7D7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_graph_rounded,
              color: GrowMateColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hãy bắt đầu bài học đầu tiên để thấy tiến trình của bạn nhé!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: GrowMateColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmChip extends StatelessWidget {
  const _RhythmChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? GrowMateColors.primary.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? GrowMateColors.primary.withValues(alpha: 0.28)
              : GrowMateColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? GrowMateColors.primary : GrowMateColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
