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
import '../bloc/diagnosis_bloc.dart';
import '../bloc/diagnosis_event.dart';
import '../bloc/diagnosis_state.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({
    super.key,
    required this.submissionId,
    required this.diagnosisRepository,
  });

  final String submissionId;
  final DiagnosisRepository diagnosisRepository;

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  late final DiagnosisBloc _diagnosisBloc;

  @override
  void initState() {
    super.initState();
    _diagnosisBloc = DiagnosisBloc(
      diagnosisRepository: widget.diagnosisRepository,
    )..add(DiagnosisRequested(widget.submissionId));
  }

  @override
  void dispose() {
    _diagnosisBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiagnosisBloc>.value(
      value: _diagnosisBloc,
      child: Scaffold(
        backgroundColor: GrowMateColors.background,
        body: SafeArea(
          child: BlocConsumer<DiagnosisBloc, DiagnosisState>(
            listener: (context, state) {
              if (state is DiagnosisFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }

              if (state is DiagnosisSuccess) {
                if (state.infoMessage != null &&
                    state.infoMessage!.isNotEmpty) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.infoMessage!)));
                }

                if (state.hitlConfirmed) {
                  context.push(
                    AppRoutes.intervention,
                    extra: <String, dynamic>{
                      'submissionId': state.submissionId,
                      'diagnosisId': state.diagnosisId,
                      'finalMode': state.finalMode,
                      'interventionPlan': state.interventionPlan,
                      'uncertaintyHigh': _isUncertaintyHigh(state),
                    },
                  );
                }
              }
            },
            builder: (context, state) {
              final theme = Theme.of(context);

              if (state is DiagnosisLoading) {
                return const _DiagnosisLoadingView();
              }

              if (state is DiagnosisFailure) {
                return ZenPageContainer(
                  child: Column(
                    children: [
                      const GrowMateTopAppBar(),
                      const SizedBox(height: 20),
                      ZenCard(
                        radius: 28,
                        child: Text(
                          'Mình chưa lấy được phân tích lần này. Bấm thử lại để tụi mình tiếp tục nhé.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: GrowMateColors.textSecondary,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ZenButton(
                        label: 'Thử lại',
                        onPressed: () {
                          context.read<DiagnosisBloc>().add(
                            DiagnosisRequested(widget.submissionId),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }

              final successState = state as DiagnosisSuccess;

              return ZenPageContainer(
                child: ListView(
                  children: [
                    const GrowMateTopAppBar(),
                    const SizedBox(height: 14),
                    ZenCard(
                      radius: 34,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0F7F8), Color(0xFFE7F0EC)],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 104,
                            height: 104,
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
                              size: 56,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            successState.headline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: GrowMateColors.primary,
                              fontSize: 35,
                              height: 1.14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đừng lo lắng nhé, những kiến thức này đôi khi hơi "khó chiều" một chút thôi.\nChúng mình cùng nhau gỡ rối nhé?',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: GrowMateColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ZenCard(
                      radius: 30,
                      color: Colors.white.withValues(alpha: 0.82),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: GrowMateColors.primaryContainer
                                      .withValues(alpha: 0.6),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: GrowMateColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'PHÂN TÍCH LỖ HỔNG',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: GrowMateColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            successState.gapAnalysis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: GrowMateColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Mức độ hoàn thiện',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: GrowMateColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '45%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: GrowMateColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: 0.45,
                              backgroundColor:
                                  GrowMateColors.surfaceContainerHigh,
                              color: GrowMateColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SkillTile(
                            icon: Icons.check_circle_rounded,
                            iconColor: GrowMateColors.success,
                            title: 'Đã vững',
                            value: successState.strengths.first,
                          ),
                          const SizedBox(height: 10),
                          _SkillTile(
                            icon: Icons.error_rounded,
                            iconColor: GrowMateColors.warningSoft,
                            title: 'Cần xem lại',
                            value: successState.needsReview.first,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ZenCard(
                      radius: 22,
                      color: GrowMateColors.secondaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Minh bạch AI: ${successState.diagnosisReason}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: GrowMateColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mình ôn lại phần này nhé?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: GrowMateColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ZenButton(
                      label: successState.isConfirming
                          ? 'Đang xử lý...'
                          : 'Đồng ý nè',
                      onPressed: successState.isConfirming
                          ? null
                          : () {
                              context.read<DiagnosisBloc>().add(
                                const HITLConfirmed(
                                  approved: true,
                                  reviewerNote:
                                      'User agreed to continue with support plan.',
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 12),
                    ZenButton(
                      label: 'Để sau nha',
                      variant: ZenButtonVariant.secondary,
                      onPressed: successState.isConfirming
                          ? null
                          : () => context.push(AppRoutes.sessionComplete),
                    ),
                    const SizedBox(height: 20),
                    const _TipBento(
                      icon: Icons.lightbulb_rounded,
                      title: 'Mẹo nhỏ:',
                      message:
                          'Hãy thử vẽ biểu đồ trước khi tính toán để dễ hình dung hơn.',
                      background: Color(0xFFE8F1E1),
                    ),
                    const SizedBox(height: 12),
                    const _TipBento(
                      icon: Icons.timer_rounded,
                      title: 'Chỉ mất khoảng 15 phút',
                      message: 'để nắm vững phần này thôi.',
                      background: Color(0xFFE4ECF6),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
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

  bool _isUncertaintyHigh(DiagnosisSuccess state) {
    final reason = state.diagnosisReason.toLowerCase();
    return state.requiresHitl ||
        state.finalMode == 'recovery' ||
        reason.contains('entropy') ||
        reason.contains('uncertain') ||
        reason.contains('khong chac') ||
        reason.contains('không chắc');
  }
}

class _DiagnosisLoadingView extends StatelessWidget {
  const _DiagnosisLoadingView();

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
                  'Mình đang phân tích để gợi ý đúng nhịp học của bạn...',
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

class _TipBento extends StatelessWidget {
  const _TipBento({
    required this.icon,
    required this.title,
    required this.message,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 24,
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GrowMateColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GrowMateColors.textPrimary,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GrowMateColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
