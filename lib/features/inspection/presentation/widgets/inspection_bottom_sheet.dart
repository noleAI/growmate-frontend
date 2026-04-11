import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/colors.dart';
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

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        alignment: Alignment.bottomCenter,
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                              title: context.t(
                                vi: 'Bảng phân tích AI',
                                en: 'AI insight panel',
                              ),
                              subtitle: context.t(
                                vi: 'AI nhận định · Cập nhật ${_formatTimestamp(state.updatedAt)}',
                                en: 'AI insights · Updated ${_formatTimestamp(state.updatedAt)}',
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
                              child: Column(
                                children: state.planSteps
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              entry.key ==
                                                  state.planSteps.length - 1
                                              ? 0
                                              : 10,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${entry.key + 1}',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _localizedDynamicText(
                                                  context,
                                                  entry.value,
                                                  fallbackEn:
                                                      'Step ${entry.key + 1} in the current plan',
                                                ),
                                                style:
                                                    theme.textTheme.bodyMedium,
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
                                      color: GrowMateColors.tertiaryContainer,
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
                                            color: GrowMateColors.success,
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
                                            color: GrowMateColors.textSecondary,
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
                                    color: GrowMateColors.success,
                                    delayMs: 150,
                                  ),
                                  ProgressBarItem(
                                    label: context.t(
                                      vi: 'Độ bất định tổng hợp',
                                      en: 'Aggregate uncertainty',
                                    ),
                                    value: state.uncertaintyScore,
                                    color: GrowMateColors.warningSoft,
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
      return Text(
        context.t(
          vi: 'Chưa có Q-value mới trong phiên hiện tại.',
          en: 'No new Q-values in the current session.',
        ),
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
        context.t(
          vi: 'Chưa có quyết định mới được ghi nhận.',
          en: 'No recent decisions recorded.',
        ),
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
                          color: GrowMateColors.textSecondary,
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
                      color: GrowMateColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t(
                      vi: 'Nguồn: ${entry.source}',
                      en: 'Source: ${_localizedDynamicText(context, entry.source, fallbackEn: 'runtime')}',
                    ),
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
