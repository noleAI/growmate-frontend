import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/repositories/diagnosis_repository.dart';
import '../cubit/result_cubit.dart';
import '../cubit/result_state.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.submissionId,
    required this.diagnosisRepository,
  });

  final String submissionId;
  final DiagnosisRepository diagnosisRepository;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ResultCubit _resultCubit;
  bool _proposalPopupVisible = false;
  String? _proposalShownForDiagnosisId;

  @override
  void initState() {
    super.initState();
    _resultCubit = ResultCubit(diagnosisRepository: widget.diagnosisRepository)
      ..loadResult(widget.submissionId);
  }

  @override
  void dispose() {
    _resultCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResultCubit>.value(
      value: _resultCubit,
      child: Scaffold(
        backgroundColor: GrowMateColors.background,
        body: SafeArea(
          child: BlocConsumer<ResultCubit, ResultState>(
            listener: (context, state) {
              if (state is! ResultReady) {
                return;
              }

              if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage!)));
                context.read<ResultCubit>().clearInfoMessage();
              }

              if (state.navigateToNextQuiz) {
                context.read<ResultCubit>().clearNavigationFlag();
                context.go(AppRoutes.quiz);
                return;
              }

              final diagnosisId = state.result.diagnosisId;
              if (diagnosisId.isEmpty || state.isAnalyzingFeedback) {
                return;
              }

              if (_proposalShownForDiagnosisId == diagnosisId ||
                  _proposalPopupVisible) {
                return;
              }

              _proposalShownForDiagnosisId = diagnosisId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _showProposalDialog(context, state.result);
              });
            },
            builder: (context, state) {
              if (state is ResultLoading) {
                return const _ResultLoadingView();
              }

              if (state is ResultFailure) {
                return _ResultErrorView(
                  message: state.message,
                  onRetry: () {
                    context.read<ResultCubit>().loadResult(widget.submissionId);
                  },
                );
              }

              final readyState = state as ResultReady;

              return Stack(
                children: [
                  _ResultContent(state: readyState),
                  IgnorePointer(
                    ignoring: !readyState.isAnalyzingFeedback,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: readyState.isAnalyzingFeedback ? 1 : 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: GrowMateColors.shadowSoft,
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'AI đang phân tích phản hồi của bạn...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GrowMateColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: GrowMateBottomNavBar(
          currentTab: GrowMateTab.today,
          onTabSelected: (tab) => handleTabNavigation(context, tab),
        ),
      ),
    );
  }

  Future<void> _showProposalDialog(
    BuildContext context,
    ResultModel result,
  ) async {
    if (_proposalPopupVisible) {
      return;
    }

    _proposalPopupVisible = true;
    final cubit = context.read<ResultCubit>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Một chút xác nhận nha'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lý do gợi ý: ${result.diagnosisReason}',
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Độ tự tin của hệ thống: ${(result.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: result.confidenceScore,
                      backgroundColor: GrowMateColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        GrowMateColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Độ bất định: ${(result.uncertaintyScore * 100).toStringAsFixed(0)}%',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: result.uncertaintyScore,
                      backgroundColor: GrowMateColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        GrowMateColors.warningSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mức rủi ro: ${result.riskLevel.toUpperCase()}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đề xuất tiếp theo: ${result.nextSuggestedTopic}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  cubit.onPlanRejected();
                },
                child: const Text('Để sau'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  cubit.onPlanAccepted();
                },
                child: const Text('Đồng ý'),
              ),
            ],
          );
        },
      );
    } finally {
      _proposalPopupVisible = false;
    }
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.state});

  final ResultReady state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.result;

    return ZenPageContainer(
      child: ListView(
        children: [
          const GrowMateTopAppBar(),
          const SizedBox(height: 14),
          ZenCard(
            radius: 32,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F7F8), Color(0xFFE7F0EC)],
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE0ECED), Color(0xFFCDDDE0)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: GrowMateColors.shadowSoft,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: GrowMateColors.primary,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  result.headline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: GrowMateColors.primary,
                    fontSize: 33,
                    height: 1.14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ZenCard(
            radius: 28,
            color: Colors.white.withValues(alpha: 0.82),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHÂN TÍCH LỖ HỔNG',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result.gapAnalysis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                _SkillTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: GrowMateColors.success,
                  title: 'Đã vững',
                  value: result.strengths.first,
                ),
                const SizedBox(height: 10),
                _SkillTile(
                  icon: Icons.lightbulb_rounded,
                  iconColor: GrowMateColors.warningSoft,
                  title: 'Cần ôn nhẹ',
                  value: result.needsReview.first,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: GrowMateColors.secondaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: GrowMateColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gợi ý tiếp theo: ${result.nextSuggestedTopic}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: GrowMateColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ZenCard(
            radius: 20,
            color: GrowMateColors.secondaryContainer.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MINH BẠCH AI',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.45,
                  ),
                ),
                const SizedBox(height: 8),
                _TransparencyHint(
                  icon: Icons.visibility_rounded,
                  text: result.diagnosisReason,
                ),
                const SizedBox(height: 8),
                _TransparencyHint(
                  icon: Icons.flag_rounded,
                  text: 'Điểm cần củng cố: ${result.needsReview.first}',
                ),
                const SizedBox(height: 8),
                _TransparencyHint(
                  icon: Icons.alt_route_rounded,
                  text: 'Lý do gợi ý bước tiếp: ${result.nextSuggestedTopic}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ZenCard(
            radius: 18,
            color: GrowMateColors.tertiaryContainer.withValues(alpha: 0.35),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Text(
              'Bước xác nhận đề xuất đã hiển thị bằng popup để bạn chọn Đồng ý hoặc Để sau.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ResultLoadingView extends StatelessWidget {
  const _ResultLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenPageContainer(
      child: Column(
        children: [
          const GrowMateTopAppBar(),
          const Spacer(),
          ZenCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            color: Colors.white.withValues(alpha: 0.8),
            child: Column(
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
                const SizedBox(height: 14),
                Text(
                  'Mình đang tổng hợp kết quả để gợi ý đúng nhịp học của bạn...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ResultErrorView extends StatelessWidget {
  const _ResultErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenPageContainer(
      child: Column(
        children: [
          const GrowMateTopAppBar(),
          const SizedBox(height: 20),
          ZenCard(
            radius: 28,
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: GrowMateColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          ZenButton(label: 'Thử lại', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GrowMateColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparencyHint extends StatelessWidget {
  const _TransparencyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: GrowMateColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
