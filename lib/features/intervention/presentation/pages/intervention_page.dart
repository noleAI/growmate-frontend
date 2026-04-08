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
import '../../data/repositories/intervention_repository.dart';
import '../bloc/intervention_bloc.dart';
import '../bloc/intervention_event.dart';
import '../bloc/intervention_state.dart';

class InterventionPage extends StatefulWidget {
  const InterventionPage({
    super.key,
    required this.submissionId,
    required this.diagnosisId,
    required this.finalMode,
    required this.interventionPlan,
    required this.interventionRepository,
    this.uncertaintyHigh = false,
  });

  final String submissionId;
  final String diagnosisId;
  final String finalMode;
  final List<Map<String, dynamic>> interventionPlan;
  final InterventionRepository interventionRepository;
  final bool uncertaintyHigh;

  @override
  State<InterventionPage> createState() => _InterventionPageState();
}

class _InterventionPageState extends State<InterventionPage> {
  late final InterventionBloc _interventionBloc;

  @override
  void initState() {
    super.initState();

    _interventionBloc = InterventionBloc(
      interventionRepository: widget.interventionRepository,
      submissionId: widget.submissionId,
      diagnosisId: widget.diagnosisId,
      finalMode: widget.finalMode,
      backendInterventionPlan: widget.interventionPlan,
      uncertaintyHigh: widget.uncertaintyHigh,
    )..add(const InterventionStarted());
  }

  @override
  void dispose() {
    _interventionBloc.close();
    super.dispose();
  }

  Future<void> _showUncertaintyDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Một chút xác nhận nha'),
          content: const Text(
            'Mình không chắc bạn đang mệt hay bối rối. Bạn muốn nghỉ hay xem gợi ý?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<InterventionBloc>().add(
                      const InterventionPromptResolved(chooseRecovery: true),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Nghỉ chút nha'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<InterventionBloc>().add(
                      const InterventionPromptResolved(chooseRecovery: false),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Xem gợi ý'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterventionBloc>.value(
      value: _interventionBloc,
      child: Scaffold(
        backgroundColor: GrowMateColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAF8E5),
                Color(0xFFEAF3F7),
                GrowMateColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: BlocConsumer<InterventionBloc, InterventionState>(
              listener: (context, state) {
                if (state.showUncertaintyPrompt) {
                  _showUncertaintyDialog(context);
                }

                final toast = state.toastMessage;
                if (toast != null && toast.isNotEmpty) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(toast)));
                  context
                      .read<InterventionBloc>()
                      .add(const InterventionMessageCleared());
                }
              },
              builder: (context, state) {
                final skipOption = state.options
                    .where((option) => option.id == 'skip_once')
                    .firstOrNull;

                final displayedOptions = state.options
                    .where((option) => option.id != 'skip_once')
                    .take(2)
                    .toList();

                return ZenPageContainer(
                  child: ListView(
                    children: [
                      const GrowMateTopAppBar(),
                      if (state.mode == InterventionMode.recovery) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 210,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(state.remainingRestSeconds),
                                style: const TextStyle(
                                  color: Color(0xFFA7B2DC),
                                  fontSize: 48,
                                  height: 1,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'THỜI GIAN HỒI PHỤC',
                                  style: TextStyle(
                                    color: GrowMateColors.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: GrowMateColors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                color: GrowMateColors.success,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'MOOD CHECK',
                                style: TextStyle(
                                  color: GrowMateColors.success,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mình chọn cách học nhẹ\nnhàng hơn nha?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GrowMateColors.primary,
                          fontSize: 31,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Học tập là một hành trình dài, mình đi\nchậm lại một chút cũng được nha. 🌿',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GrowMateColors.textSecondary,
                          fontSize: 20,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...displayedOptions.map((option) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _InterventionOptionCard(
                            option: option,
                            isSubmitting: state.isSubmitting,
                            onTap: () {
                              context
                                  .read<InterventionBloc>()
                                  .add(InterventionOptionSelected(option));
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      ZenButton(
                        label: skipOption?.label ?? 'Bỏ qua lần này cũng không sao',
                        variant: ZenButtonVariant.text,
                        onPressed: state.isSubmitting || skipOption == null
                            ? null
                            : () {
                                context.read<InterventionBloc>().add(
                                      InterventionOptionSelected(skipOption),
                                    );
                              },
                      ),
                      const SizedBox(height: 18),
                      const ZenCard(
                        radius: 26,
                        color: Color(0xFFFAF9F6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Spacer(),
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFD8D8D8),
                                  size: 48,
                                ),
                              ],
                            ),
                            Text(
                              'Gợi ý từ GrowMate',
                              style: TextStyle(
                                color: GrowMateColors.textSecondary,
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '"Hôm nay có vẻ bạn đang hơi mệt.\nHãy dành 5 phút nghe một bản nhạc\nkhông lời trước khi bắt đầu nhé."',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GrowMateColors.textPrimary,
                                fontSize: 20,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ZenButton(
                        label: state.feedbackRecorded
                            ? 'Kết thúc phiên học'
                            : 'Tiếp tục học ngay',
                        onPressed: () {
                          if (state.feedbackRecorded) {
                            context.push(AppRoutes.sessionComplete);
                            return;
                          }
                          context.push(AppRoutes.quiz);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: GrowMateBottomNavBar(
          currentTab: GrowMateTab.today,
          onTabSelected: (tab) => handleTabNavigation(context, tab),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _InterventionOptionCard extends StatelessWidget {
  const _InterventionOptionCard({
    required this.option,
    required this.isSubmitting,
    required this.onTap,
  });

  final InterventionOption option;
  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconByType(option.type);
    final iconBg = _iconBgByType(option.type);

    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: ZenCard(
        radius: 26,
        color: Colors.white.withValues(alpha: 0.84),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: GrowMateColors.primary, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      color: GrowMateColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descriptionByType(option.type),
                    style: const TextStyle(
                      color: GrowMateColors.textSecondary,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA3A3A3),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconByType(String type) {
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return Icons.spa_rounded;
    }
    if (type.contains('practice')) {
      return Icons.extension_rounded;
    }
    return Icons.menu_book_rounded;
  }

  static Color _iconBgByType(String type) {
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return GrowMateColors.tertiaryContainer;
    }
    if (type.contains('practice')) {
      return const Color(0xFFE7F1E5);
    }
    return const Color(0xFFE4E7FA);
  }

  static String _descriptionByType(String type) {
    if (type.contains('practice')) {
      return 'Các câu hỏi vừa sức để bạn lấy lại tự tin.';
    }
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return 'Thả lỏng vài phút để lấy lại nhịp học nhẹ nhàng.';
    }
    return 'Xem lại các kiến thức cũ nhẹ nhàng.';
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
