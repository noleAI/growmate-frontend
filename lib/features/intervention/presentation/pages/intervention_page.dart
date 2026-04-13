import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
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
  bool _blocInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_blocInitialized) {
      return;
    }

    _blocInitialized = true;
    _interventionBloc = InterventionBloc(
      interventionRepository: widget.interventionRepository,
      submissionId: widget.submissionId,
      diagnosisId: widget.diagnosisId,
      finalMode: widget.finalMode,
      backendInterventionPlan: widget.interventionPlan,
      uncertaintyHigh: widget.uncertaintyHigh,
      isEnglish: context.isEnglish,
    )..add(const InterventionStarted());
  }

  @override
  void dispose() {
    if (_blocInitialized) {
      _interventionBloc.close();
    }
    super.dispose();
  }

  Future<void> _showUncertaintyDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.t(vi: 'Một chút xác nhận nha', en: 'Quick confirmation'),
          ),
          content: Text(
            context.t(
              vi: 'Mình không chắc bạn đang mệt hay bối rối. Bạn muốn nghỉ hay xem gợi ý?',
              en: 'I\'m not sure whether you are tired or confused. Do you want a break or guidance?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<InterventionBloc>().add(
                  const InterventionPromptResolved(chooseRecovery: true),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                context.t(vi: 'Nghỉ chút nha', en: 'Take a short break'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<InterventionBloc>().add(
                  const InterventionPromptResolved(chooseRecovery: false),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text(context.t(vi: 'Xem gợi ý', en: 'Show guidance')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<InterventionBloc>.value(
      value: _interventionBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFEFF7E8),
                const Color(0xFFEAF2F5),
                theme.colorScheme.surface,
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
                  context.read<InterventionBloc>().add(
                    const InterventionMessageCleared(),
                  );
                }
              },
              builder: (context, state) {
                final theme = Theme.of(context);

                final skipOption = state.options
                    .where((option) => option.id == 'skip_once')
                    .firstOrNull;

                final displayedOptions = state.options
                    .where((option) => option.id != 'skip_once')
                    .take(2)
                    .toList();

                return ZenPageContainer(
                  includeBottomSafeArea: false,
                  child: ListView(
                    children: [
                      const GrowMateTopAppBar(),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: context.t(vi: 'Quay lại', en: 'Back'),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                            context.go(AppRoutes.home);
                          },
                          padding: EdgeInsets.all(12),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (state.mode == InterventionMode.recovery) ...[
                        const SizedBox(height: GrowMateLayout.space12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final timerHeight = (availableHeight * 0.28).clamp(
                              160.0,
                              240.0,
                            );
                            return SizedBox(
                              height: timerHeight,
                              child: ZenCard(
                                radius: 28,
                                padding: const EdgeInsets.all(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF4FAF3),
                                    Color(0xFFE7F0EA),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatDuration(
                                        state.remainingRestSeconds,
                                      ),
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: 46,
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        context.t(
                                          vi: 'THỜI GIAN HỒI PHỤC',
                                          en: 'RECOVERY TIME',
                                        ),
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: GrowMateLayout.space16),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: 0.16,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.eco_rounded,
                                color: theme.colorScheme.tertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.t(
                                  vi: 'KIỂM TRA TÂM TRẠNG',
                                  en: 'MOOD CHECK',
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.tertiary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: GrowMateLayout.space16),
                      Text(
                        context.t(
                          vi: 'Mình chọn cách học nhẹ\nnhàng hơn nha?',
                          en: 'Shall we switch to a\ngentler study flow?',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t(
                          vi: 'Học tập là một hành trình dài, mình đi\nchậm lại một chút cũng được nha. 🌿',
                          en: 'Learning is a long journey, and it is okay\nto slow down a little. 🌿',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: GrowMateLayout.sectionGap),
                      ...displayedOptions.map((option) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _InterventionOptionCard(
                            option: option,
                            isSubmitting: state.isSubmitting,
                            onTap: () {
                              context.read<InterventionBloc>().add(
                                InterventionOptionSelected(option),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 2),
                      ZenButton(
                        label: _localizedOptionLabel(
                          context,
                          skipOption,
                          fallback: context.t(
                            vi: 'Bỏ qua lần này cũng không sao',
                            en: 'Skip this time',
                          ),
                        ),
                        variant: ZenButtonVariant.text,
                        onPressed: state.isSubmitting || skipOption == null
                            ? null
                            : () {
                                context.read<InterventionBloc>().add(
                                  InterventionOptionSelected(skipOption),
                                );
                              },
                      ),
                      const SizedBox(height: GrowMateLayout.space12),
                      ZenCard(
                        radius: 26,
                        color: const Color(0xFFFAF9F6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
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
                              context.t(
                                vi: 'Gợi ý từ GrowMate',
                                en: 'Suggestion from GrowMate',
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.t(
                                vi: '"Hôm nay có vẻ bạn đang hơi mệt.\nHãy dành 5 phút nghe một bản nhạc\nkhông lời trước khi bắt đầu nhé."',
                                en: '"You seem a bit tired today.\nTake 5 minutes to listen to instrumental music\nbefore starting."',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 5,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: GrowMateLayout.space16),
                      ZenButton(
                        label: state.feedbackRecorded
                            ? context.t(
                                vi: 'Kết thúc phiên học',
                                en: 'Finish this session',
                              )
                            : context.t(
                                vi: 'Tiếp tục học ngay',
                                en: 'Continue studying now',
                              ),
                        onPressed: () {
                          if (state.feedbackRecorded) {
                            final selectedOption = state.options
                                .where(
                                  (option) =>
                                      option.id == state.selectedOptionId,
                                )
                                .firstOrNull;
                            final selectedLabel = _localizedOptionLabel(
                              context,
                              selectedOption,
                              fallback: state.selectedOptionLabel,
                            );
                            final location = Uri(
                              path: AppRoutes.sessionComplete,
                              queryParameters: <String, String>{
                                'submissionId': widget.submissionId,
                                'diagnosisId': widget.diagnosisId,
                                'mode': state.mode == InterventionMode.recovery
                                    ? 'recovery'
                                    : 'academic',
                                'topic': selectedLabel,
                                'nextAction': selectedLabel,
                              },
                            ).toString();
                            context.push(location);
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
      ),
    );
  }

  String _localizedOptionLabel(
    BuildContext context,
    InterventionOption? option, {
    String? fallback,
  }) {
    if (option == null) {
      return fallback ??
          context.t(vi: 'Bỏ qua lần này cũng không sao', en: 'Skip this time');
    }

    if (!context.isEnglish) {
      return option.label;
    }

    final id = option.id.toLowerCase();
    final type = option.type.toLowerCase();

    if (id == 'skip_once') {
      return 'Skip this time';
    }

    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return 'Take a short mindful break';
    }

    if (type.contains('practice')) {
      return 'Do a lighter practice set';
    }

    if (type.contains('review') || type.contains('academic')) {
      return 'Review core concepts gently';
    }

    return option.label;
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
    final theme = Theme.of(context);
    final icon = _iconByType(option.type);
    final iconBg = _iconBgByType(option.type, theme.colorScheme);
    final showDefaultBadge = !option.fromBackend;

    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: Stack(
        children: [
          ZenCard(
            radius: 24,
            color: Colors.white.withValues(alpha: 0.86),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(
                      GrowMateLayout.cardRadius,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: theme.colorScheme.primary, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelByType(context, option),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descriptionByType(context, option.type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA3A3A3),
                  size: 28,
                ),
              ],
            ),
          ),
          if (showDefaultBadge)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: Text(
                  context.t(vi: 'Mặc định', en: 'Default'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
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

  static Color _iconBgByType(String type, ColorScheme colorScheme) {
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return colorScheme.tertiaryContainer;
    }
    if (type.contains('practice')) {
      return const Color(0xFFE7F1E5);
    }
    return const Color(0xFFE4E7FA);
  }

  static String _labelByType(BuildContext context, InterventionOption option) {
    if (!context.isEnglish) {
      return option.label;
    }

    final id = option.id.toLowerCase();
    final type = option.type.toLowerCase();
    if (id == 'skip_once') {
      return 'Skip this time';
    }
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return 'Take a mindful break';
    }
    if (type.contains('practice')) {
      return 'Do a lighter practice set';
    }
    if (type.contains('review') || type.contains('academic')) {
      return 'Review core concepts';
    }
    return option.label;
  }

  static String _descriptionByType(BuildContext context, String type) {
    if (type.contains('practice')) {
      return context.t(
        vi: 'Các câu hỏi vừa sức để bạn lấy lại tự tin.',
        en: 'Gentle questions to help you regain confidence.',
      );
    }
    if (type.contains('breath') ||
        type.contains('ground') ||
        type.contains('recovery')) {
      return context.t(
        vi: 'Thả lỏng vài phút để lấy lại nhịp học nhẹ nhàng.',
        en: 'Relax for a few minutes to recover a gentle study rhythm.',
      );
    }
    return context.t(
      vi: 'Xem lại các kiến thức cũ nhẹ nhàng.',
      en: 'Review previous concepts in a gentle way.',
    );
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
