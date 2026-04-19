import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../data/models/inspection_ops_models.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../cubit/inspection_cubit.dart';

class InspectionBottomSheet extends StatefulWidget {
  const InspectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<InspectionCubit>();
    if (!cubit.state.canInspect) {
      return Future<void>.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider<InspectionCubit>.value(
          value: cubit,
          child: const InspectionBottomSheet(),
        );
      },
    );
  }

  @override
  State<InspectionBottomSheet> createState() => _InspectionBottomSheetState();
}

class _InspectionBottomSheetState extends State<InspectionBottomSheet> {
  @override
  void initState() {
    super.initState();
    context.read<InspectionCubit>().startLiveSync();
  }

  @override
  void dispose() {
    context.read<InspectionCubit>().stopLiveSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InspectionCubit>();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: StreamBuilder<InspectionState>(
              stream: cubit.stream,
              initialData: cubit.state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? cubit.state;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 48,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SectionHeader(
                              title: context.t(
                                vi: 'Bảng phân tích AI',
                                en: 'AI insight panel',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: cubit.refreshNow,
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (state.runtimeLoading)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: const LinearProgressIndicator(
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            InsightCard(
                              title: context.t(
                                vi: 'Runtime metrics',
                                en: 'Runtime metrics',
                              ),
                              subtitle: context.t(
                                vi: 'Nguồn ${state.runtimeFromServer ? 'server' : 'local fallback'} · Cập nhật ${_formatTimestamp(state.runtimeUpdatedAt)}',
                                en: 'Source ${state.runtimeFromServer ? 'server' : 'local fallback'} · Updated ${_formatTimestamp(state.runtimeUpdatedAt)}',
                              ),
                              delayMs: 20,
                              child: _RuntimeMetricsGrid(
                                metrics: state.runtimeMetrics,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Runtime alerts',
                                en: 'Runtime alerts',
                              ),
                              subtitle: context.t(
                                vi: 'Cảnh báo vận hành theo ngưỡng thời gian thực',
                                en: 'Operational alerts generated from runtime thresholds',
                              ),
                              delayMs: 30,
                              child: _RuntimeAlertsList(
                                alerts: state.runtimeAlerts,
                                errorMessage: state.runtimeErrorMessage,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'AI nhận định',
                                en: 'AI beliefs',
                              ),
                              subtitle: context.t(
                                vi: 'Phân bố niềm tin theo chủ đề',
                                en: 'Belief distribution by topic',
                              ),
                              delayMs: 40,
                              child: Column(
                                children: state.beliefs
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => ProgressBarItem(
                                        label: _localizedDynamicText(
                                          context,
                                          entry.value.topic,
                                          fallbackEn: 'Topic ${entry.key + 1}',
                                        ),
                                        value: entry.value.ratio,
                                        color: theme.colorScheme.primary,
                                        delayMs: 60 + entry.key * 25,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Kế hoạch hành động',
                                en: 'Action plan',
                              ),
                              subtitle: context.t(
                                vi: 'Cây kế hoạch rút gọn cho phiên hiện tại',
                                en: 'Compact plan tree for the current session',
                              ),
                              delayMs: 70,
                              child: state.planSteps.isEmpty
                                  ? Text(
                                      context.t(
                                        vi: 'Chưa có kế hoạch cho phiên này.',
                                        en: 'No plan steps for this session yet.',
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    )
                                  : Column(
                                      children: state.planSteps
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _PlanStepRow(
                                              label: _localizedDynamicText(
                                                context,
                                                entry.value,
                                                fallbackEn:
                                                    'Step ${entry.key + 1} in the current plan',
                                              ),
                                              isLast:
                                                  entry.key ==
                                                  state.planSteps.length - 1,
                                              rawText: entry.value,
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Trạng thái tinh thần',
                                en: 'Mental state',
                              ),
                              subtitle: context.t(
                                vi: 'Trạng thái hiện tại của người học',
                                en: 'Current learner state',
                              ),
                              delayMs: 100,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _localizedDynamicText(
                                        context,
                                        state.mentalStateLabel,
                                        fallbackEn: 'Stable',
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.tertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _localizedDynamicText(
                                        context,
                                        state.mentalStateHint,
                                        fallbackEn:
                                            'Current learning state inferred from recent AI signals.',
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Độ tin cậy',
                                en: 'Confidence metrics',
                              ),
                              subtitle: context.t(
                                vi: 'Độ tin cậy mô hình và độ bất định',
                                en: 'Model confidence and uncertainty',
                              ),
                              delayMs: 130,
                              child: Column(
                                children: [
                                  ProgressBarItem(
                                    label: context.t(
                                      vi: 'Độ tin cậy mô hình',
                                      en: 'Model confidence',
                                    ),
                                    value: state.confidenceScore,
                                    color: theme.colorScheme.tertiary,
                                    delayMs: 150,
                                  ),
                                  ProgressBarItem(
                                    label: context.t(
                                      vi: 'Độ bất định tổng hợp',
                                      en: 'Aggregate uncertainty',
                                    ),
                                    value: state.uncertaintyScore,
                                    color: theme.colorScheme.secondary,
                                    delayMs: 180,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Q-Value ưu tiên',
                                en: 'Priority Q-values',
                              ),
                              subtitle: context.t(
                                vi: 'Giá trị chiến lược đang được mô hình ưu tiên',
                                en: 'Strategy values currently prioritized by the model',
                              ),
                              delayMs: 160,
                              child: _QValueList(qValues: state.qValues),
                            ),
                            const SizedBox(height: 12),
                            InsightCard(
                              title: context.t(
                                vi: 'Nhật ký quyết định',
                                en: 'Decision log',
                              ),
                              subtitle: context.t(
                                vi: 'Các quyết định gần nhất',
                                en: 'Most recent decisions',
                              ),
                              delayMs: 190,
                              child: _DecisionList(entries: state.decisionLogs),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static String _formatTimestamp(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _RuntimeMetricsGrid extends StatelessWidget {
  const _RuntimeMetricsGrid({required this.metrics});

  final Map<String, int> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.isEmpty) {
      return Text(
        context.t(
          vi: 'Chưa có số liệu runtime ở thời điểm hiện tại.',
          en: 'No runtime metrics are available right now.',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final entries = metrics.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .take(8)
              .map((entry) {
                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _metricLabel(context, entry.key),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  static String _metricLabel(BuildContext context, String key) {
    switch (key) {
      case 'signature_expired_total':
        return context.t(vi: 'Chữ ký hết hạn', en: 'Expired signatures');
      case 'quiz_result_fetch_failures_total':
        return context.t(vi: 'Lỗi lấy kết quả', en: 'Result fetch failures');
      case 'resume_signature_grace_used_total':
        return context.t(
          vi: 'Số lần dùng grace resume',
          en: 'Resume grace usage',
        );
      case 'belief_topics_count':
        return context.t(vi: 'Số chủ đề belief', en: 'Belief topics');
      case 'plan_steps_count':
        return context.t(vi: 'Số bước plan', en: 'Plan steps');
      case 'decision_logs_count':
        return context.t(vi: 'Số decision logs', en: 'Decision logs');
      case 'q_values_count':
        return context.t(vi: 'Số Q-values', en: 'Q-values');
      case 'confidence_percent':
        return context.t(vi: 'Độ tin cậy (%)', en: 'Confidence (%)');
      case 'uncertainty_percent':
        return context.t(vi: 'Độ bất định (%)', en: 'Uncertainty (%)');
      default:
        return key;
    }
  }
}

class _RuntimeAlertsList extends StatelessWidget {
  const _RuntimeAlertsList({required this.alerts, required this.errorMessage});

  final List<InspectionRuntimeAlertItem> alerts;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null && errorMessage!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (alerts.isEmpty)
          Text(
            context.t(
              vi: 'Không có cảnh báo runtime vượt ngưỡng.',
              en: 'No runtime alerts are currently above threshold.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...alerts
              .take(6)
              .map(
                (alert) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _severityBgColor(context, alert.severity),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              alert.severity.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _severityFgColor(
                                  context,
                                  alert.severity,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(alert.observedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _localizedDynamicText(
                          context,
                          alert.message,
                          fallbackEn:
                              'Runtime alert was generated from backend thresholds.',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t(
                          vi: '${_RuntimeMetricsGrid._metricLabel(context, alert.metric)}: ${alert.value} / ${alert.threshold}',
                          en: '${_RuntimeMetricsGrid._metricLabel(context, alert.metric)}: ${alert.value} / ${alert.threshold}',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  static Color _severityBgColor(BuildContext context, String severity) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = severity.toLowerCase();

    if (normalized == 'warning') {
      return scheme.tertiaryContainer;
    }
    if (normalized == 'error' || normalized == 'critical') {
      return scheme.errorContainer;
    }
    return scheme.secondaryContainer;
  }

  static Color _severityFgColor(BuildContext context, String severity) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = severity.toLowerCase();

    if (normalized == 'warning') {
      return scheme.tertiary;
    }
    if (normalized == 'error' || normalized == 'critical') {
      return scheme.error;
    }
    return scheme.secondary;
  }

  static String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _QValueList extends StatelessWidget {
  const _QValueList({required this.qValues});

  final Map<String, double> qValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (qValues.isEmpty) {
      return Text(
        context.t(
          vi: 'Chưa có Q-value mới trong phiên hiện tại.',
          en: 'No new Q-values in the current session.',
        ),
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final sortedEntries = qValues.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries
          .asMap()
          .entries
          .map(
            (entry) => ProgressBarItem(
              label: entry.value.key,
              value: entry.value.value,
              trailingLabel: entry.value.value.toStringAsFixed(3),
              delayMs: 210 + entry.key * 20,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DecisionList extends StatelessWidget {
  const _DecisionList({required this.entries});

  final List<InspectionDecisionLog> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Text(
        context.t(
          vi: 'Chưa có quyết định mới được ghi nhận.',
          en: 'No recent decisions recorded.',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: entries
          .take(6)
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _localizedDynamicText(
                            context,
                            entry.action,
                            fallbackEn: 'Model decision update',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(entry.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _localizedDynamicText(
                      context,
                      entry.reason,
                      fallbackEn:
                          'Decision rationale was updated from current runtime signals.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t(
                      vi: 'Nguồn: ${entry.source}',
                      en: 'Source: ${_localizedDynamicText(context, entry.source, fallbackEn: 'runtime')}',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// A single row in the plan tree timeline visualization.
///
/// Parses a simple status prefix from [rawText]:
/// - Starts with "✓" or "[done]"/"[completed]" → completed (green)
/// - Starts with "→" or "[active]"/"[current]" → active (primary)
/// - Otherwise → pending (neutral)
class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({
    required this.label,
    required this.isLast,
    required this.rawText,
  });

  final String label;
  final bool isLast;
  final String rawText;

  _PlanStepStatus get _status {
    final lower = rawText.trim().toLowerCase();
    if (lower.startsWith('✓') ||
        lower.startsWith('[done]') ||
        lower.startsWith('[completed]')) {
      return _PlanStepStatus.completed;
    }
    if (lower.startsWith('→') ||
        lower.startsWith('[active]') ||
        lower.startsWith('[current]')) {
      return _PlanStepStatus.active;
    }
    return _PlanStepStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;

    final Color dotColor;
    final Color dotBorder;
    final Color lineColor;
    final Color bgColor;
    final Color textColor;

    switch (status) {
      case _PlanStepStatus.completed:
        dotColor = const Color(0xFF1E8E5B);
        dotBorder = const Color(0xFF1E8E5B);
        lineColor = const Color(0xFF1E8E5B);
        bgColor = const Color(0xFFE6F6ED);
        textColor = const Color(0xFF1E8E5B);
        break;
      case _PlanStepStatus.active:
        dotColor = theme.colorScheme.primary;
        dotBorder = theme.colorScheme.primary;
        lineColor = theme.colorScheme.primary.withValues(alpha: 0.35);
        bgColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.primary;
        break;
      case _PlanStepStatus.pending:
        dotColor = theme.colorScheme.surfaceContainerHigh;
        dotBorder = theme.colorScheme.outline;
        lineColor = theme.colorScheme.surfaceContainerHigh.withValues(
          alpha: 0.8,
        );
        bgColor = theme.colorScheme.surfaceContainerHigh;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column: dot + connector line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: status == _PlanStepStatus.pending
                      ? Colors.transparent
                      : dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotBorder, width: 2),
                ),
                child: status == _PlanStepStatus.completed
                    ? Icon(Icons.check_rounded, size: 8, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Text + status chip
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: status == _PlanStepStatus.active
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: status == _PlanStepStatus.pending
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (status != _PlanStepStatus.pending) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == _PlanStepStatus.completed ? '✓' : '▶',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _PlanStepStatus { completed, active, pending }

String _localizedDynamicText(
  BuildContext context,
  String value, {
  required String fallbackEn,
}) {
  final trimmed = value.trim();
  if (!context.isEnglish) {
    return trimmed;
  }

  if (trimmed.isEmpty) {
    return fallbackEn;
  }

  final hasVietnameseChars = RegExp(
    r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
  ).hasMatch(trimmed);

  if (hasVietnameseChars) {
    return fallbackEn;
  }

  return trimmed;
}
