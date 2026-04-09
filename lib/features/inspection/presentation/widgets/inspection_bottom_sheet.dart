import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/colors.dart';
import '../cubit/inspection_cubit.dart';

class InspectionBottomSheet extends StatefulWidget {
  const InspectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<InspectionCubit>();

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
    final theme = Theme.of(context);
    final cubit = context.read<InspectionCubit>();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: GrowMateColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: StreamBuilder<InspectionState>(
            stream: cubit.stream,
            initialData: cubit.state,
            builder: (context, snapshot) {
              final state = snapshot.data ?? cubit.state;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: GrowMateColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: GrowMateColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.visibility_rounded,
                            color: GrowMateColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mini Inspection Dashboard',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: cubit.refreshNow,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: GrowMateColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cập nhật: ${_formatTimestamp(state.updatedAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: GrowMateColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Belief Distribution (Bayesian)',
                      child: Column(
                        children: state.beliefs
                            .map(
                              (belief) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BeliefBar(belief: belief),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Current Plan Tree (HTN)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.planSteps
                            .map(
                              (step) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.subdirectory_arrow_right_rounded,
                                        size: 18,
                                        color: GrowMateColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Mental State (Particle Filter)',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: GrowMateColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Trạng thái: ${state.mentalStateLabel}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.mentalStateHint,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Confidence & Uncertainty',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricRow(
                            label: 'Model confidence',
                            value:
                                '${(state.confidenceScore * 100).toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: state.confidenceScore,
                              backgroundColor:
                                  GrowMateColors.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                GrowMateColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: 'Aggregate uncertainty',
                            value:
                                '${(state.uncertaintyScore * 100).toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: state.uncertaintyScore,
                              backgroundColor:
                                  GrowMateColors.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                GrowMateColors.warningSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Q-Value View (Memory)',
                      child: state.qValues.isEmpty
                          ? Text(
                              'Chưa có cập nhật Q-value từ tương tác gần đây.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.textSecondary,
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final sortedEntries =
                                    state.qValues.entries.toList(
                                      growable: false,
                                    )..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    );

                                return Column(
                                  children: sortedEntries
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _QValueBar(
                                            strategy: entry.key,
                                            score: entry.value,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Decision Log',
                      child: state.decisionLogs.isEmpty
                          ? Text(
                              'Chưa có quyết định nào được ghi nhận trong phiên hiện tại.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: state.decisionLogs
                                  .take(8)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _DecisionTile(entry: entry),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GrowMateColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: GrowMateColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _BeliefBar extends StatelessWidget {
  const _BeliefBar({required this.belief});

  final InspectionBelief belief;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                belief.topic,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              belief.percentageLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: belief.ratio,
            backgroundColor: GrowMateColors.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(
              GrowMateColors.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _QValueBar extends StatelessWidget {
  const _QValueBar({required this.strategy, required this.score});

  final String strategy;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedScore = score.clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strategy,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              score.toStringAsFixed(3),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: normalizedScore,
            backgroundColor: GrowMateColors.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(
              GrowMateColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({required this.entry});

  final InspectionDecisionLog entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GrowMateColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.action,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GrowMateColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatTime(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GrowMateColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: GrowMateColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'source: ${entry.source}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GrowMateColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (entry.uncertaintyScore != null)
                  Text(
                    'uncertainty ${(entry.uncertaintyScore! * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: GrowMateColors.warningSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: GrowMateColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
