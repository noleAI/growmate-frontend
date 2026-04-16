import 'package:flutter/material.dart';

import '../../../../core/constants/layout.dart';
import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
          titleSpacing: 0,
          title: Text(
            context.t(vi: 'Lộ trình học', en: 'Learning path'),
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
          includeBottomSafeArea: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress summary card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.t(
                              vi: 'THPT 2026 — Tiến độ của bạn',
                              en: 'THPT 2026 — Your progress',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          '35%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.35,
                        minHeight: 7,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.t(
                            vi: '2 / 10 chủ đề hoàn thành',
                            en: '2 / 10 topics done',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.t(vi: '3 môn học', en: '3 subjects'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              // ── Tabs ──────────────────────────────────────────────────
              TabBar(
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge,
                dividerColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
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
                      completedPercent: 0.35,
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
                        ...roadmapSubjects.map(
                          (subject) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: RoadmapCardItem(
                              title: subject.title,
                              subtitle: subject.subtitle,
                              leading: const IconLeading(
                                icon: Icons.calculate_rounded,
                              ),
                              progress: 0.35,
                              progressLabel: context.t(
                                vi: 'Đang học: 35%',
                                en: 'In progress: 35%',
                              ),
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
                          ),
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
