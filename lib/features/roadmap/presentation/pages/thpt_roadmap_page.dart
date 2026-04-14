import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../quiz/domain/entities/quiz_question_template.dart';

class ThptRoadmapPage extends StatelessWidget {
  const ThptRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        includeBottomSafeArea: false,
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (notification) {
              notification.disallowIndicator();
              return false;
            },
            child: ListView(
              children: [
                const GrowMateTopAppBar(avatarNotificationOnly: true),
                const SizedBox(height: GrowMateLayout.sectionGap),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(
                          vi: 'Lộ trình: Đạo hàm cơ bản',
                          en: 'Roadmap: Basic Derivatives',
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t(
                          vi: 'Tập trung vào 4 nhóm kỹ năng đạo hàm. Hoàn thành từng bước để nắm vững chủ đề.',
                          en: 'Focus on 4 derivative skill groups. Complete each step to master the topic.',
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t(
                            vi: 'MVP: GrowMate đang tập trung hoàn toàn vào chủ đề "Đạo hàm cơ bản" để mang lại trải nghiệm học tốt nhất.',
                            en: 'MVP: GrowMate is fully focused on "Basic Derivatives" to deliver the best learning experience.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GrowMateLayout.sectionGap),
                ..._hypothesisTopics.map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HypothesisTopicCard(data: topic),
                  ),
                ),
                const SizedBox(height: GrowMateLayout.sectionGap),
                _SectionTitle(
                  title: context.t(
                    vi: 'Lộ trình 4 giai đoạn',
                    en: '4-Stage Learning Path',
                  ),
                ),
                const SizedBox(height: GrowMateLayout.space12),
                _DerivativeRoadmapSteps(),
                const SizedBox(height: GrowMateLayout.space24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.roadmap,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hypothesis Topic Card — 1 card per H01-H04
// ─────────────────────────────────────────────────────────────────────────────

class _HypothesisTopicCard extends StatelessWidget {
  const _HypothesisTopicCard({required this.data});

  final _HypothesisTopicData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
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
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    data.tag.storageValue,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.tag.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle.of(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(data.icon, size: 22, color: colors.primary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.description.of(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.examples
                .map(
                  (example) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      example,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
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

// ─────────────────────────────────────────────────────────────────────────────
// Derivative Roadmap Steps — 4 learning phases
// ─────────────────────────────────────────────────────────────────────────────

class _DerivativeRoadmapSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoadmapStepLine(
            index: 1,
            phase: context.t(vi: 'Nền tảng', en: 'Foundation'),
            duration: context.t(vi: '3-5 ngày', en: '3-5 days'),
            focus: context.t(
              vi: 'Ôn lại quy tắc tính cơ bản (H04): tổng, hiệu, tích, thương. Chốt công thức nền.',
              en: 'Review basic rules (H04): sum, difference, product, quotient. Lock core formulas.',
            ),
          ),
          _RoadmapStepLine(
            index: 2,
            phase: context.t(vi: 'Mở rộng', en: 'Expand'),
            duration: context.t(vi: '5-7 ngày', en: '5-7 days'),
            focus: context.t(
              vi: 'Đạo hàm lượng giác (H01) và mũ-logarit (H02). Luyện từng dạng riêng.',
              en: 'Trig derivatives (H01) and exp-log (H02). Practice each type separately.',
            ),
          ),
          _RoadmapStepLine(
            index: 3,
            phase: context.t(vi: 'Tổng hợp', en: 'Synthesis'),
            duration: context.t(vi: '5-7 ngày', en: '5-7 days'),
            focus: context.t(
              vi: 'Chain Rule (H03): hàm hợp kết hợp nhiều dạng. Đây là phần khó nhất.',
              en: 'Chain Rule (H03): composite functions. This is the hardest part.',
            ),
          ),
          _RoadmapStepLine(
            index: 4,
            phase: context.t(vi: 'Nước rút', en: 'Final Sprint'),
            duration: context.t(vi: '3-5 ngày', en: '3-5 days'),
            focus: context.t(
              vi: 'Luyện đề tổng hợp 4 dạng, ôn lỗi sai thường gặp, tăng tốc độ giải.',
              en: 'Mixed practice across all 4 types, review common mistakes, increase speed.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapStepLine extends StatelessWidget {
  const _RoadmapStepLine({
    required this.index,
    required this.phase,
    required this.duration,
    required this.focus,
  });

  final int index;
  final String phase;
  final String duration;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$phase ($duration): ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: focus),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _LocalizedText {
  const _LocalizedText({required this.vi, required this.en});

  final String vi;
  final String en;

  String of(BuildContext context) {
    return context.t(vi: vi, en: en);
  }
}

class _HypothesisTopicData {
  const _HypothesisTopicData({
    required this.tag,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.examples,
  });

  final HypothesisTag tag;
  final _LocalizedText subtitle;
  final _LocalizedText description;
  final IconData icon;
  final List<String> examples;
}

const _hypothesisTopics = <_HypothesisTopicData>[
  _HypothesisTopicData(
    tag: HypothesisTag.h04BasicRules,
    subtitle: _LocalizedText(
      vi: 'Bắt đầu từ đây',
      en: 'Start here',
    ),
    description: _LocalizedText(
      vi: 'Quy tắc đạo hàm tổng, hiệu, tích, thương. Nền tảng cần nắm vững trước khi đi tiếp.',
      en: 'Sum, difference, product, quotient rules. Foundation you must master before moving on.',
    ),
    icon: Icons.foundation_rounded,
    examples: ["(u+v)' = u'+v'", "(uv)' = u'v+uv'", "(u/v)' = ..."],
  ),
  _HypothesisTopicData(
    tag: HypothesisTag.h01TrigDerivative,
    subtitle: _LocalizedText(
      vi: 'Đạo hàm sin, cos, tan',
      en: 'Derivatives of sin, cos, tan',
    ),
    description: _LocalizedText(
      vi: 'Công thức đạo hàm các hàm lượng giác cơ bản và mở rộng.',
      en: 'Derivative formulas for basic and extended trigonometric functions.',
    ),
    icon: Icons.waves_rounded,
    examples: ["(sin x)' = cos x", "(cos x)' = -sin x", "(tan x)' = 1/cos²x"],
  ),
  _HypothesisTopicData(
    tag: HypothesisTag.h02ExpLogDerivative,
    subtitle: _LocalizedText(
      vi: 'Mũ và logarit tự nhiên',
      en: 'Exponential & natural log',
    ),
    description: _LocalizedText(
      vi: 'Đạo hàm hàm mũ eˣ, aˣ và logarit ln x, log_a(x).',
      en: 'Derivatives of exponential eˣ, aˣ and logarithm ln x, log_a(x).',
    ),
    icon: Icons.trending_up_rounded,
    examples: ["(eˣ)' = eˣ", "(ln x)' = 1/x", "(aˣ)' = aˣ·ln a"],
  ),
  _HypothesisTopicData(
    tag: HypothesisTag.h03ChainRule,
    subtitle: _LocalizedText(
      vi: 'Hàm hợp — phần khó nhất',
      en: 'Composite functions — hardest part',
    ),
    description: _LocalizedText(
      vi: 'Chain Rule: đạo hàm hàm hợp f(g(x)). Kết hợp nhiều dạng, đòi hỏi phân tích cấu trúc.',
      en: 'Chain Rule: derivatives of composite f(g(x)). Combines multiple types, requires structural analysis.',
    ),
    icon: Icons.link_rounded,
    examples: ["(f∘g)' = f'(g)·g'", "(sin 2x)' = 2cos 2x", "(e^(x²))' = 2x·e^(x²)"],
  ),
];

