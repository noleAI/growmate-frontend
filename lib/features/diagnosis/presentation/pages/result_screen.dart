import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/ai_components.dart';
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
  bool _showDecisionAnalyzing = false;
  bool _navigationTriggered = false;
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
                _resultCubit.clearInfoMessage();
              }

              if (state.navigateToNextQuiz) {
                if (_navigationTriggered) {
                  return;
                }

                _navigationTriggered = true;
                _resultCubit.clearNavigationFlag();
                final router = GoRouter.of(context);

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Lộ trình học của bạn đã được cập nhật'),
                    ),
                  );

                Future<void>.delayed(const Duration(milliseconds: 780), () {
                  if (!mounted) {
                    return;
                  }
                  router.go(AppRoutes.quiz);
                });
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
                _showDecisionMoment(state.result);
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
                    _resultCubit.loadResult(widget.submissionId);
                  },
                );
              }

              final readyState = state as ResultReady;
              final showOverlay =
                  readyState.isAnalyzingFeedback || _showDecisionAnalyzing;
              final overlayMessage = _showDecisionAnalyzing
                  ? 'Đang phân tích hiệu suất của bạn...'
                  : 'AI đang xử lý phản hồi của bạn...';

              return Stack(
                children: [
                  _ResultContent(state: readyState),
                  IgnorePointer(
                    ignoring: !showOverlay,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: showOverlay ? 1 : 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Container(
                          width: 290,
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                overlayMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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

  Future<void> _showDecisionMoment(ResultModel result) async {
    if (_proposalPopupVisible) {
      return;
    }

    _proposalPopupVisible = true;

    try {
      if (mounted) {
        setState(() {
          _showDecisionAnalyzing = true;
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return;
      }

      setState(() {
        _showDecisionAnalyzing = false;
      });

      final action = await AiResultModal.show(
        context,
        didWell: result.strengths.take(2).toList(growable: false),
        needsImprovement: result.needsReview.take(2).toList(growable: false),
        nextStep: result.nextSuggestedTopic,
        subtitle:
            'Độ tự tin ${(result.confidenceScore * 100).toStringAsFixed(0)}% · Rủi ro ${_riskLabel(result.riskLevel)}',
      );

      if (!mounted || action == null) {
        return;
      }

      if (action == AiResultAction.applyPlan) {
        await _resultCubit.onPlanAccepted();
      } else {
        await _resultCubit.onPlanRejected();
      }
    } finally {
      if (mounted) {
        setState(() {
          _showDecisionAnalyzing = false;
        });
      }
      _proposalPopupVisible = false;
    }
  }

  String _riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'CAO';
      case 'medium':
        return 'TRUNG BÌNH';
      case 'low':
        return 'THẤP';
      default:
        return riskLevel.toUpperCase();
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
                  title: 'Cần củng cố',
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
                          'Gợi ý bước tiếp theo: ${result.nextSuggestedTopic}',
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
                  text: 'Lỗ hổng ưu tiên: ${result.needsReview.first}',
                ),
                const SizedBox(height: 8),
                _TransparencyHint(
                  icon: Icons.alt_route_rounded,
                  text: 'Lý do bước tiếp theo: ${result.nextSuggestedTopic}',
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
              'Khoảnh khắc ra quyết định của AI sẽ tự động kích hoạt sau mỗi bài hoàn thành.',
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
                  'AI đang phân tích hiệu suất của bạn...',
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
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
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
