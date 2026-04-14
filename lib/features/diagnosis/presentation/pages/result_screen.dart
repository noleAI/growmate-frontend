import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/ai_components.dart';
import '../../../../shared/widgets/premium_sections.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_error_card.dart';
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
  bool _showTransitionOverlay = false;
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocConsumer<ResultCubit, ResultState>(
            listener: (context, state) {
              if (state is! ResultReady) {
                return;
              }

              if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
                final localizedInfoMessage = _localizedResultMessage(
                  context,
                  state.infoMessage!,
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(localizedInfoMessage)));
                _resultCubit.clearInfoMessage();
              }

              if (state.navigateToIntervention) {
                if (_navigationTriggered) {
                  return;
                }

                _navigationTriggered = true;
                _resultCubit.clearNavigationFlag();
                final router = GoRouter.of(context);

                setState(() {
                  _showTransitionOverlay = true;
                });

                Future<void>.delayed(const Duration(milliseconds: 1200), () {
                  if (!mounted) {
                    return;
                  }
                  router.go(
                    AppRoutes.intervention,
                    extra: <String, dynamic>{
                      'submissionId': state.result.submissionId,
                      'diagnosisId': state.result.diagnosisId,
                      'finalMode': state.result.finalMode,
                      'interventionPlan': state.result.interventionPlan,
                      'uncertaintyHigh': _isUncertaintyHigh(state.result),
                    },
                  );
                });
                return;
              }

              // Modal is now triggered manually via CTA button.
            },
            builder: (context, state) {
              final theme = Theme.of(context);

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
                  readyState.isAnalyzingFeedback ||
                  _showDecisionAnalyzing ||
                  _showTransitionOverlay;
              final overlayMessage = _showTransitionOverlay
                  ? context.t(
                      vi: 'Đang chuyển sang bước can thiệp...',
                      en: 'Moving to the intervention step...',
                    )
                  : _showDecisionAnalyzing
                  ? context.t(
                      vi: 'Đang phân tích hiệu suất của bạn...',
                      en: 'Analyzing your performance...',
                    )
                  : context.t(
                      vi: 'AI đang xử lý phản hồi của bạn...',
                      en: 'AI is processing your feedback...',
                    );

              return Stack(
                children: [
                  _ResultContent(
                    state: readyState,
                    onShowProposal: () =>
                        _showDecisionMoment(readyState.result),
                    proposalShown:
                        _proposalShownForDiagnosisId ==
                        readyState.result.diagnosisId,
                  ),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
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
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
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

      await Future<void>.delayed(const Duration(milliseconds: 850));

      if (!mounted) {
        return;
      }

      setState(() {
        _showDecisionAnalyzing = false;
      });

      final action = await AiResultModal.show(
        context,
        didWell: result.strengths
            .take(2)
            .map(
              (item) => _localizedDynamicText(
                context,
                item,
                fallbackEn: 'You maintained a stable study rhythm.',
              ),
            )
            .toList(growable: false),
        needsImprovement: result.needsReview
            .take(2)
            .map(
              (item) => _localizedDynamicText(
                context,
                item,
                fallbackEn: 'Review one core concept before moving forward.',
              ),
            )
            .toList(growable: false),
        nextStep: _localizedDynamicText(
          context,
          result.nextSuggestedTopic,
          fallbackEn: 'Continue with one focused review topic.',
        ),
        subtitle: context.t(
          vi: 'Độ tự tin ${(result.confidenceScore * 100).toStringAsFixed(0)}% · Rủi ro ${_riskLabel(context, result.riskLevel)}',
          en: 'Confidence ${(result.confidenceScore * 100).toStringAsFixed(0)}% · Risk ${_riskLabel(context, result.riskLevel)}',
        ),
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

  String _localizedResultMessage(BuildContext context, String message) {
    if (!context.isEnglish) {
      return message;
    }

    final trimmed = message.trim();
    switch (trimmed) {
      case 'Lộ trình học của bạn đã được cập nhật':
        return 'Your study roadmap has been updated.';
      case 'Xác nhận tạm lỗi. Mình thử lại một lần nữa nhé.':
        return 'Confirmation had a temporary issue. Please try once more.';
      default:
        if (_containsVietnameseChars(trimmed)) {
          return 'Update completed successfully.';
        }
        return trimmed;
    }
  }

  bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
  }

  String _riskLabel(BuildContext context, String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return context.t(vi: 'CAO', en: 'HIGH');
      case 'medium':
        return context.t(vi: 'TRUNG BÌNH', en: 'MEDIUM');
      case 'low':
        return context.t(vi: 'THẤP', en: 'LOW');
      default:
        return riskLevel.toUpperCase();
    }
  }

  bool _isUncertaintyHigh(ResultModel result) {
    if (result.requiresHitl) {
      return true;
    }

    if (result.finalMode == 'recovery') {
      return true;
    }

    if (result.uncertaintyScore >= 0.45) {
      return true;
    }

    return result.riskLevel.toLowerCase() == 'high';
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

class _ResultContent extends StatelessWidget {
  const _ResultContent({
    required this.state,
    required this.onShowProposal,
    this.proposalShown = false,
  });

  final ResultReady state;
  final VoidCallback onShowProposal;
  final bool proposalShown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.result;

    return ZenPageContainer(
      includeBottomSafeArea: false,
      child: ListView(
        children: [
          const GrowMateTopAppBar(),
          const SizedBox(height: 32),
          Text(
            context.t(vi: 'Kết quả phân tích AI', en: 'AI analysis result'),
            style: theme.textTheme.displayLarge?.copyWith(height: 1.05),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'AI vừa hoàn tất quyết định và cập nhật lộ trình tiếp theo.',
              en: 'AI has completed the decision and updated your next roadmap.',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizedDynamicText(
                          context,
                          result.headline,
                          fallbackEn: 'Learning snapshot',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 30,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t(
                          vi: 'Độ tự tin ${(result.confidenceScore * 100).toStringAsFixed(0)}% · Rủi ro ${_riskLabel(context, result.riskLevel)}',
                          en: 'Confidence ${(result.confidenceScore * 100).toStringAsFixed(0)}% · Risk ${_riskLabel(context, result.riskLevel)}',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Section(
            title: context.t(vi: 'Tóm tắt chẩn đoán', en: 'Diagnosis summary'),
            subtitle: context.t(
              vi: 'Điều gì đang diễn ra và AI đề xuất gì ngay bây giờ',
              en: 'What is happening now and what AI suggests next',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedDynamicText(
                    context,
                    result.gapAnalysis,
                    fallbackEn:
                        'AI identified a key gap and prepared a focused next step for your upcoming session.',
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 14),
                _PointRow(
                  icon: Icons.check_circle_rounded,
                  color: theme.colorScheme.tertiary,
                  label: context.t(vi: 'Đã vững', en: 'Strong area'),
                  value: _localizedDynamicText(
                    context,
                    result.strengths.first,
                    fallbackEn: 'Fundamental rules and stability',
                  ),
                ),
                const SizedBox(height: 10),
                _PointRow(
                  icon: Icons.warning_rounded,
                  color: theme.colorScheme.secondary,
                  label: context.t(
                    vi: 'Cần củng cố',
                    en: 'Needs reinforcement',
                  ),
                  value: _localizedDynamicText(
                    context,
                    result.needsReview.first,
                    fallbackEn: 'Apply concepts in timed questions',
                  ),
                ),
                const SizedBox(height: 10),
                _PointRow(
                  icon: Icons.alt_route_rounded,
                  color: theme.colorScheme.primary,
                  label: context.t(vi: 'Bước tiếp theo', en: 'Next step'),
                  value: _localizedDynamicText(
                    context,
                    result.nextSuggestedTopic,
                    fallbackEn: 'A focused review topic for the next session',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Section(
            title: context.t(
              vi: 'Minh bạch quyết định AI',
              en: 'AI decision transparency',
            ),
            subtitle: context.t(
              vi: 'Vì sao AI đưa ra lộ trình này',
              en: 'Why AI chose this roadmap',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HintLine(
                  icon: Icons.visibility_rounded,
                  text: _localizedDynamicText(
                    context,
                    result.diagnosisReason,
                    fallbackEn:
                        'The recommendation is based on confidence, review gaps, and recent learning behavior signals.',
                  ),
                ),
                const SizedBox(height: 10),
                _HintLine(
                  icon: Icons.flag_rounded,
                  text: context.t(
                    vi: 'Lỗ hổng ưu tiên: ${_localizedDynamicText(context, result.needsReview.first, fallbackEn: 'Vận dụng khái niệm vào câu hỏi tính giờ')}',
                    en: 'Priority gap: ${_localizedDynamicText(context, result.needsReview.first, fallbackEn: 'Applying concepts in timed questions')}',
                  ),
                ),
                const SizedBox(height: 10),
                _HintLine(
                  icon: Icons.update_rounded,
                  text: context.t(
                    vi: 'Khoảnh khắc quyết định AI được kích hoạt sau mỗi bài hoàn thành.',
                    en: 'The AI decision moment is triggered after each completed quiz.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ParticleFilterSection(result: result),
          const SizedBox(height: 24),
          ZenButton(
            label: proposalShown
                ? context.t(vi: 'Xem lại đề xuất AI', en: 'Review AI proposal')
                : context.t(vi: 'Xem đề xuất AI ✨', en: 'View AI proposal ✨'),
            onPressed: onShowProposal,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _riskLabel(BuildContext context, String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return context.t(vi: 'CAO', en: 'HIGH');
      case 'medium':
        return context.t(vi: 'TRUNG BÌNH', en: 'MEDIUM');
      case 'low':
        return context.t(vi: 'THẤP', en: 'LOW');
      default:
        return riskLevel.toUpperCase();
    }
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticleFilterSection extends StatelessWidget {
  const _ParticleFilterSection({required this.result});

  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentalState = result.mentalState;
    final distribution = result.particleDistribution;

    return Section(
      title: context.t(
        vi: 'Trạng thái tinh thần (Particle Filter)',
        en: 'Mental state (Particle Filter)',
      ),
      subtitle: context.t(
        vi: 'Ước lượng bởi Empathy Agent từ tín hiệu hành vi',
        en: 'Estimated by Empathy Agent from behavioral signals',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MentalStateChip(mentalState: mentalState),
          if (distribution.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...distribution.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ParticleBar(
                  label: _stateLabel(context, entry.key),
                  value: entry.value,
                  isActive: entry.key == mentalState,
                  theme: theme,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Uncertainty: ${(result.uncertaintyScore * 100).toStringAsFixed(0)}%',
              en: 'Uncertainty: ${(result.uncertaintyScore * 100).toStringAsFixed(0)}%',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(BuildContext context, String state) {
    switch (state) {
      case 'focused':
        return context.t(vi: '🟢 Tập trung', en: '🟢 Focused');
      case 'confused':
        return context.t(vi: '🟡 Bối rối', en: '🟡 Confused');
      case 'exhausted':
        return context.t(vi: '🔴 Kiệt sức', en: '🔴 Exhausted');
      case 'frustrated':
        return context.t(vi: '🟠 Thất vọng', en: '🟠 Frustrated');
      default:
        return state;
    }
  }
}

class _MentalStateChip extends StatelessWidget {
  const _MentalStateChip({required this.mentalState});

  final String mentalState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (String label, Color color, IconData icon) = switch (mentalState) {
      'focused' => (
        context.t(vi: 'Tập trung', en: 'Focused'),
        theme.colorScheme.tertiary,
        Icons.check_circle_rounded,
      ),
      'confused' => (
        context.t(vi: 'Bối rối', en: 'Confused'),
        theme.colorScheme.secondary,
        Icons.help_rounded,
      ),
      'exhausted' => (
        context.t(vi: 'Kiệt sức', en: 'Exhausted'),
        theme.colorScheme.error,
        Icons.battery_alert_rounded,
      ),
      'frustrated' => (
        context.t(vi: 'Thất vọng', en: 'Frustrated'),
        Colors.orange,
        Icons.sentiment_dissatisfied_rounded,
      ),
      _ => (
        mentalState,
        theme.colorScheme.onSurfaceVariant,
        Icons.psychology_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            context.t(vi: 'Trạng thái: $label', en: 'State: $label'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticleBar extends StatelessWidget {
  const _ParticleBar({
    required this.label,
    required this.value,
    required this.isActive,
    required this.theme,
  });

  final String label;
  final double value;
  final bool isActive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final barColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultLoadingView extends StatelessWidget {
  const _ResultLoadingView();

  @override
  Widget build(BuildContext context) {
    return ZenPageContainer(
      child: Column(
        children: [
          const GrowMateTopAppBar(),
          const Spacer(),
          Section(
            title: context.t(
              vi: 'Đang tổng hợp kết quả',
              en: 'Compiling result',
            ),
            subtitle: context.t(
              vi: 'AI đang phân tích hiệu suất của bạn...',
              en: 'AI is analyzing your performance...',
            ),
            child: const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
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
    return ZenPageContainer(
      child: Column(
        children: [
          const GrowMateTopAppBar(),
          const SizedBox(height: GrowMateLayout.sectionGap),
          ZenErrorCard(message: message, onRetry: onRetry),
        ],
      ),
    );
  }
}
