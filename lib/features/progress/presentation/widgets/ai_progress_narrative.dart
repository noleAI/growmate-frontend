import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/ai_blocks/ai_block_base.dart';
import '../../../../shared/widgets/ai_blocks/ai_block_model.dart';
import '../../../../shared/widgets/ambient/decision_badge.dart';
import '../../../../shared/widgets/confidence/confidence_arc.dart';
import '../../data/mock_user_progress_generator.dart';

/// 3-level AI Progress Narrative widget per UI spec Section 2.4.
///
/// Level 1: Headline AI assessment + dual-value arc gauge.
/// Level 2: Expandable per-topic mastery breakdown.
/// Level 3: Collapsible AI reasoning chain.
class AiProgressNarrative extends StatefulWidget {
  const AiProgressNarrative({
    super.key,
    required this.progress,
    this.updatedAgo = '2h trước',
    this.onWhyTap,
    this.onTopicTap,
    this.isConfirmed = true,
  });

  final UserProgressSnapshot progress;
  final String updatedAgo;
  final VoidCallback? onWhyTap;
  final ValueChanged<String>? onTopicTap;
  final bool isConfirmed;

  @override
  State<AiProgressNarrative> createState() => _AiProgressNarrativeState();
}

class _AiProgressNarrativeState extends State<AiProgressNarrative> {
  bool _breakdownExpanded = true;
  bool _reasoningExpanded = false;

  /// Average mastery across all topics (strong).
  double get _strongConfidence {
    if (widget.progress.masteryMap.isEmpty) return 0;
    final strong = widget.progress.masteryMap.where((t) => t.score >= 3.0);
    if (strong.isEmpty) return 0;
    return strong.map((t) => t.score / 4).reduce((a, b) => a + b) /
        strong.length;
  }

  /// Average mastery for topics needing work.
  double get _weakConfidence {
    if (widget.progress.masteryMap.isEmpty) return 0;
    final weak = widget.progress.masteryMap.where((t) => t.score < 3.0);
    if (weak.isEmpty) return 0;
    return weak.map((t) => t.score / 4).reduce((a, b) => a + b) / weak.length;
  }

  String _topicLabel(String topic) {
    const map = {
      // Hypothesis IDs from backend
      'H01_Trig': 'Lượng giác',
      'H01_trig': 'Lượng giác',
      'H02_ExpLog': 'Mũ & Logarit',
      'H02_explog': 'Mũ & Logarit',
      'H03_Chain': 'Quy tắc dây chuyền',
      'H03_chain': 'Quy tắc dây chuyền',
      'H04_Rules': 'Quy tắc cơ bản',
      'H04_rules': 'Quy tắc cơ bản',
      'H05_Limits': 'Giới hạn',
      'H05_limits': 'Giới hạn',
      'H06_Integration': 'Tích phân',
      'H06_integration': 'Tích phân',
      // Backend snake_case IDs
      'chain_rule': 'Quy tắc dây chuyền',
      'derivatives': 'Đạo hàm cơ bản',
      'trigonometry': 'Lượng giác',
      'limits': 'Giới hạn',
      'integration': 'Tích phân',
      'logarithm': 'Logarit',
      'exponential': 'Hàm mũ',
      'polynomial': 'Đa thức',
      'applications': 'Ứng dụng thực tế',
      'basic_derivatives': 'Đạo hàm cơ bản',
      'arithmetic_rules': 'Quy tắc số học',
      'basic_trig': 'Lượng giác cơ bản',
      'exp_log': 'Mũ & Logarit',
    };
    // Normalize: strip underscores for matching if not found directly
    return map[topic] ?? map[topic.toLowerCase()] ?? _humanizeTopicCode(topic);
  }

  /// Convert raw codes like 'H04_Rules' → 'Quy tắc' fallback label.
  String _humanizeTopicCode(String code) {
    // Remove leading hypothesis prefix like H01_, H02_
    final stripped = code.replaceFirst(
      RegExp(r'^H\d+_', caseSensitive: false),
      '',
    );
    // Convert snake_case / PascalCase to spaced words
    return stripped
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .replaceAll('_', ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final strong = _strongConfidence;
    final weak = _weakConfidence;

    // Determine headline text
    final hasStrong = widget.progress.masteryMap.any((t) => t.score >= 3.0);
    final hasWeak = widget.progress.masteryMap.any((t) => t.score < 3.0);

    final String headline;
    if (widget.progress.isEmpty) {
      headline = context.t(
        vi: 'Hoàn thành phiên đầu để AI bắt đầu theo dõi.',
        en: 'Complete your first session for AI to start tracking.',
      );
    } else if (hasStrong && hasWeak) {
      final strongTopic = widget.progress.masteryMap
          .where((t) => t.score >= 3.0)
          .reduce((a, b) => a.score > b.score ? a : b);
      final weakTopic = widget.progress.masteryMap
          .where((t) => t.score < 3.0)
          .reduce((a, b) => a.score < b.score ? a : b);
      headline = context.t(
        vi: 'Bạn đang tiến bộ ở ${_topicLabel(strongTopic.topic)}, nhưng ${_topicLabel(weakTopic.topic)} cần ưu tiên.',
        en: 'You\'re progressing in ${_topicLabel(strongTopic.topic)}, but ${_topicLabel(weakTopic.topic)} needs focus.',
      );
    } else if (!hasWeak) {
      headline = context.t(
        vi: 'Xuất sắc — tất cả chủ đề đều đang tốt. Sẵn sàng nâng cấp!',
        en: 'Excellent — all topics are solid. Ready to level up!',
      );
    } else {
      headline = context.t(
        vi: 'AI đang quan sát lộ trình của bạn. Tiếp tục ôn tập để AI cập nhật.',
        en: 'AI is observing your path. Keep practising to update the model.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Level 1: Headline ─────────────────────────────────────────────
        _Level1Card(
          headline: headline,
          strongConfidence: strong,
          weakConfidence: weak,
          updatedAgo: widget.updatedAgo,
          onWhyTap: () =>
              setState(() => _reasoningExpanded = !_reasoningExpanded),
          isEmpty: widget.progress.isEmpty,
          isConfirmed: widget.isConfirmed,
        ),
        const SizedBox(height: GrowMateLayout.breath),

        // ── Level 2: Breakdown ────────────────────────────────────────────
        if (!widget.progress.isEmpty) ...[
          _Level2Card(
            masteryMap: widget.progress.masteryMap,
            expanded: _breakdownExpanded,
            onToggle: () =>
                setState(() => _breakdownExpanded = !_breakdownExpanded),
            topicLabelFn: _topicLabel,
            onTopicTap: widget.onTopicTap,
          ),
          const SizedBox(height: GrowMateLayout.breath),

          // ── Level 3: AI Reasoning ─────────────────────────────────────
          _Level3Card(
            masteryMap: widget.progress.masteryMap,
            expanded: _reasoningExpanded,
            onToggle: () =>
                setState(() => _reasoningExpanded = !_reasoningExpanded),
            topicLabelFn: _topicLabel,
          ),
        ],
      ],
    );
  }
}

// ── Level 1 ──────────────────────────────────────────────────────────────────

class _Level1Card extends StatelessWidget {
  const _Level1Card({
    required this.headline,
    required this.strongConfidence,
    required this.weakConfidence,
    required this.updatedAgo,
    required this.onWhyTap,
    required this.isEmpty,
    required this.isConfirmed,
  });

  final String headline;
  final double strongConfidence;
  final double weakConfidence;
  final String updatedAgo;
  final VoidCallback onWhyTap;
  final bool isEmpty;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(
        vi: 'AI nhận định tuần này',
        en: 'AI weekly assessment',
      ),
      accentColor: GrowMateColors.aiCore(Theme.of(context).brightness),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final arcSize = isCompact ? 88.0 : 96.0;
          final metricWidth = isCompact
              ? constraints.maxWidth
              : (constraints.maxWidth - 16) / 2;

          final statusText = isConfirmed
              ? context.t(
                  vi: 'AI cập nhật $updatedAgo',
                  en: 'AI updated $updatedAgo',
                )
              : context.t(
                  vi: 'Dữ liệu tạm thời · có thể chưa chính xác',
                  en: 'Data provisional · may be approximate',
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              if (!isEmpty) ...[
                const SizedBox(height: GrowMateLayout.breath),
                Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: metricWidth,
                      child: Center(
                        child: ConfidenceArc(
                          confidence: strongConfidence,
                          size: arcSize,
                          strokeWidth: 6,
                          label: context.t(vi: 'Tự tin', en: 'Confident'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: metricWidth,
                      child: Center(
                        child: ConfidenceArc(
                          confidence: weakConfidence,
                          size: arcSize,
                          strokeWidth: 6,
                          label: context.t(vi: 'Cần ôn', en: 'Needs review'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: GrowMateLayout.breathSm),
              if (isCompact) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DecisionBadge(label: 'Vì sao?', onTap: onWhyTap),
                ),
              ] else
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DecisionBadge(label: 'Vì sao?', onTap: onWhyTap),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Level 2 ──────────────────────────────────────────────────────────────────

class _Level2Card extends StatelessWidget {
  const _Level2Card({
    required this.masteryMap,
    required this.expanded,
    required this.onToggle,
    required this.topicLabelFn,
    this.onTopicTap,
  });

  final List<TopicMastery> masteryMap;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(String) topicLabelFn;
  final ValueChanged<String>? onTopicTap;

  Color _barColor(double score, Brightness brightness) {
    if (score >= 3.0) return GrowMateColors.confident(brightness);
    if (score >= 2.0) return GrowMateColors.uncertain(brightness);
    return GrowMateColors.lowConfidence(brightness);
  }

  String _statusLabel(BuildContext context, double score) {
    if (score >= 3.0) return context.t(vi: 'Nắm chắc', en: 'Strong');
    if (score >= 2.0) return context.t(vi: 'Cần ôn lại', en: 'Needs review');
    return context.t(vi: 'Ưu tiên ôn', en: 'Priority');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiBlockBase(
      blockLabel: context.t(vi: 'Chi tiết từng chủ đề', en: 'Topic breakdown'),
      accentColor: GrowMateColors.aiCore(
        theme.brightness,
      ).withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Row(
              children: [
                Text(
                  expanded
                      ? context.t(vi: 'Ẩn chi tiết', en: 'Hide detail')
                      : context.t(vi: 'Xem chi tiết ↓', en: 'View detail ↓'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.aiCore(theme.brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: GrowMateColors.aiCore(theme.brightness),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: masteryMap
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TopicRow(
                          label: topicLabelFn(item.topic),
                          value: item.score / 4,
                          color: _barColor(item.score, theme.brightness),
                          statusLabel: _statusLabel(context, item.score),
                          onTap: onTopicTap != null
                              ? () => onTopicTap!(item.topic)
                              : null,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.label,
    required this.value,
    required this.color,
    required this.statusLabel,
    this.onTap,
  });

  final String label;
  final double value;
  final Color color;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = '${(value * 100).round()}%';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                pct,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Level 3 ──────────────────────────────────────────────────────────────────

class _Level3Card extends StatelessWidget {
  const _Level3Card({
    required this.masteryMap,
    required this.expanded,
    required this.onToggle,
    required this.topicLabelFn,
  });

  final List<TopicMastery> masteryMap;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(String) topicLabelFn;

  List<ReasoningStep> _buildSteps(BuildContext context) {
    final steps = <ReasoningStep>[];
    int i = 1;
    for (final item in masteryMap.where((t) => t.score < 3.0).take(3)) {
      steps.add(
        ReasoningStep(
          index: i++,
          description: context.t(
            vi: '${topicLabelFn(item.topic)}: điểm ${item.score.toStringAsFixed(1)}/4 — ${item.statusLabel}',
            en: '${topicLabelFn(item.topic)}: score ${item.score.toStringAsFixed(1)}/4 — ${item.statusLabel}',
          ),
        ),
      );
    }
    if (masteryMap.any((t) => t.score >= 3.0)) {
      steps.add(
        ReasoningStep(
          index: i++,
          description: context.t(
            vi: 'Mô hình Bayesian xác nhận tiến bộ ở các chủ đề mạnh.',
            en: 'Bayesian model confirms progress in strong topics.',
          ),
        ),
      );
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _buildSteps(context);

    return AiBlockBase(
      blockLabel: context.t(
        vi: 'Vì sao AI đánh giá vậy?',
        en: 'Why AI thinks this',
      ),
      accentColor: GrowMateColors.aiCore(
        theme.brightness,
      ).withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: GrowMateColors.aiCore(theme.brightness),
                ),
                const SizedBox(width: 6),
                Text(
                  context.t(
                    vi: expanded ? 'Ẩn chuỗi lập luận' : '⊕ Xem chuỗi lập luận',
                    en: expanded
                        ? 'Hide reasoning chain'
                        : '⊕ View reasoning chain',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.aiCore(theme.brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: GrowMateColors.aiWhisper(theme.brightness),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${step.index}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: GrowMateColors.aiCore(theme.brightness),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: GrowMateColors.uncertain(theme.brightness),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.t(
                          vi: 'Dữ liệu dựa trên các phiên gần đây · Bayesian model',
                          en: 'Data from recent sessions · Bayesian model',
                        ),
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: GrowMateColors.uncertain(theme.brightness),
                        ),
                      ),
                    ],
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
