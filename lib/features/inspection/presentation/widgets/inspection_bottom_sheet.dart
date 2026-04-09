import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/ai_components.dart';
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
    final cubit = context.read<InspectionCubit>();
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: GrowMateColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: GrowMateColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionHeader(
                      title: 'AI Insight Panel',
                      subtitle:
                          'AI nhận định · Cập nhật ${_formatTimestamp(state.updatedAt)}',
                      trailing: IconButton(
                        onPressed: cubit.refreshNow,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: GrowMateColors.primary,
                        ),
                      ),
                    ),
                    InsightCard(
                      title: 'AI nhận định',
                      subtitle: 'Belief distribution theo chủ đề',
                      delayMs: 40,
                      child: Column(
                        children: state.beliefs
                            .asMap()
                            .entries
                            .map(
                              (entry) => ProgressBarItem(
                                label: entry.value.topic,
                                value: entry.value.ratio,
                                color: GrowMateColors.primary,
                                delayMs: 60 + entry.key * 25,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InsightCard(
                      title: 'Kế hoạch hành động',
                      subtitle: 'Plan tree rút gọn cho phiên hiện tại',
                      delayMs: 70,
                      child: Column(
                        children: state.planSteps
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      entry.key == state.planSteps.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: GrowMateColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                          color: GrowMateColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.value,
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
                    InsightCard(
                      title: 'Mental state',
                      subtitle: 'Trạng thái hiện tại của người học',
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
                              color: GrowMateColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              state.mentalStateLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
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
                    InsightCard(
                      title: 'Độ tin cậy',
                      subtitle: 'Model confidence và uncertainty',
                      delayMs: 130,
                      child: Column(
                        children: [
                          ProgressBarItem(
                            label: 'Model confidence',
                            value: state.confidenceScore,
                            color: GrowMateColors.success,
                            delayMs: 150,
                          ),
                          ProgressBarItem(
                            label: 'Aggregate uncertainty',
                            value: state.uncertaintyScore,
                            color: GrowMateColors.warningSoft,
                            delayMs: 180,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InsightCard(
                      title: 'Q-Value ưu tiên',
                      subtitle: 'Giá trị chiến lược đang được model ưu tiên',
                      delayMs: 160,
                      child: _QValueList(qValues: state.qValues),
                    ),
                    const SizedBox(height: 12),
                    InsightCard(
                      title: 'Decision log',
                      subtitle: 'Các quyết định gần nhất',
                      delayMs: 190,
                      child: _DecisionList(entries: state.decisionLogs),
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

class _QValueList extends StatelessWidget {
  const _QValueList({required this.qValues});

  final Map<String, double> qValues;

  @override
  Widget build(BuildContext context) {
    if (qValues.isEmpty) {
      return const Text(
        'Chưa có Q-value mới trong phiên hiện tại.',
        style: TextStyle(
          color: GrowMateColors.textSecondary,
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
        'Chưa có quyết định mới được ghi nhận.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: GrowMateColors.textSecondary,
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
                color: GrowMateColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.action,
                          style: theme.textTheme.bodyMedium?.copyWith(
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nguồn: ${entry.source}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: GrowMateColors.textSecondary,
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
