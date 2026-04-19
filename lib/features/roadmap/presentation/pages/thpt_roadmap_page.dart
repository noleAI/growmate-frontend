import 'package:flutter/material.dart';

import '../../../../core/constants/layout.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/models/feature_availability.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/feature_availability_banner.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import 'roadmap_learning_data.dart';
import 'topic_screen.dart';
import '../widgets/roadmap_card_item.dart';
import '../widgets/subject_node_graph.dart';

class ThptRoadmapPage extends StatelessWidget {
  const ThptRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Compute dynamic counts from the data
    final totalTopics = roadmapSubjects.fold<int>(
      0,
      (sum, subject) => sum + subject.topics.length,
    );
    final totalSubjects = roadmapSubjects.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: IconThemeData(color: colors.primary),
          titleSpacing: 0,
          title: Text(
            context.t(vi: 'Lộ trình học', en: 'Learning path'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
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
                  color: colors.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        body: ZenPageContainer(
          includeBottomSafeArea: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress summary card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primaryContainer.withValues(alpha: 0.5),
                      colors.primaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.route_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t(
                                  vi: 'THPT 2026 — Lộ trình Toán',
                                  en: 'THPT 2026 — Math Path',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.t(
                                  vi: '$totalSubjects môn · $totalTopics chủ đề',
                                  en: '$totalSubjects subject · $totalTopics topics',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.auto_stories_rounded,
                            label: context.t(
                              vi: '$totalTopics chủ đề',
                              en: '$totalTopics topics',
                            ),
                            colors: colors,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.psychology_alt_rounded,
                            label: context.t(vi: 'AI hỗ trợ', en: 'AI-powered'),
                            colors: colors,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              FeatureAvailabilityBanner(
                availability: FeatureAvailability.beta,
                message: context.t(
                  vi: 'Roadmap này vẫn là local beta/hardcoded. Không nên trình bày như backend roadmap đồng bộ thật.',
                  en: 'This roadmap is still a local beta/hardcoded view. Do not present it as a fully synced backend roadmap.',
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              // ── Tabs ──────────────────────────────────────────────────
              TabBar(
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge,
                dividerColor: colors.outlineVariant.withValues(alpha: 0.5),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded, size: 14),
                        const SizedBox(width: 5),
                        Text(context.t(vi: 'Bản đồ', en: 'Map')),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(context.t(vi: 'Danh sách', en: 'List')),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 0: Node graph
                    SubjectNodeGraph(
                      subjects: roadmapSubjects,
                      completedPercent: 0.0,
                      onNodeTap: (subject, topic) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TopicScreen(subject: subject),
                          ),
                        );
                      },
                    ),
                    // Tab 1: Card list
                    ListView(
                      padding: const EdgeInsets.only(
                        top: GrowMateLayout.sectionGap,
                      ),
                      children: [
                        ...roadmapSubjects.expand(
                          (subject) => [
                            // Subject header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                subject.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            // Topic cards
                            ...subject.topics.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final topic = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RoadmapCardItem(
                                  title: topic.title,
                                  subtitle:
                                      '${topic.subtopics.length} bài · ${topic.subtitle}',
                                  leading: _TopicNumberBadge(
                                    number: idx + 1,
                                    colors: colors,
                                  ),
                                  progress: null,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            TopicScreen(subject: subject),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        ),
                        const SizedBox(height: GrowMateLayout.space24),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: GrowMateBottomNavBar(
          currentTab: GrowMateTab.today,
          onTabSelected: (tab) => handleTabNavigation(context, tab),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicNumberBadge extends StatelessWidget {
  const _TopicNumberBadge({required this.number, required this.colors});

  final int number;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
