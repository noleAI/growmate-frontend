import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';

import '../../../../app/router/app_routes.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Trang quiz chẩn đoán trình độ – bước 3/4.
class OnboardingQuizPage extends StatelessWidget {
  const OnboardingQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.onboardingGoal);
            }
          },
        ),
        title: Text(context.t(vi: 'Kiểm tra nhanh', en: 'Quick assessment')),
      ),
      body: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingComplete) {
            context.go(AppRoutes.onboardingResult);
          }
        },
        child: const _QuizBody(),
      ),
    );
  }
}

class _QuizBody extends StatefulWidget {
  const _QuizBody();

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  int? _selectedOption;
  int _lastIndex = -1;

  void _submit() {
    final sel = _selectedOption;
    if (sel == null) return;
    final state = context.read<OnboardingCubit>().state;
    if (state is! OnboardingQuizInProgress) return;
    context.read<OnboardingCubit>().answerQuestion(state.current.id, sel);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      OnboardingCubit,
      OnboardingState,
      OnboardingQuizInProgress?
    >(
      selector: (state) => state is OnboardingQuizInProgress ? state : null,
      builder: (context, quizState) {
        if (quizState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Reset selection when question changes
        if (_lastIndex != quizState.currentIndex) {
          _lastIndex = quizState.currentIndex;
          _selectedOption = null;
        }

        return _buildQuizContent(context, quizState);
      },
    );
  }

  Widget _buildQuizContent(
    BuildContext context,
    OnboardingQuizInProgress quizState,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final q = quizState.current;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Progress
            _StepIndicator(
              currentStep: quizState.progress,
              totalSteps: quizState.total,
            ),
            const SizedBox(height: 8),
            Text(
              'Câu ${quizState.progress}/${quizState.total}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Question
            Text(
              q.questionText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Options
            Expanded(
              child: ListView.separated(
                itemCount: q.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final isSelected = _selectedOption == i;
                  return _OptionTile(
                    label: q.options[i].text,
                    index: i,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedOption = i),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selectedOption != null ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                quizState.isLast
                    ? context.t(vi: 'Xem kết quả', en: 'View results')
                    : context.t(vi: 'Tiếp theo →', en: 'Next →'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : colors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _letters[index % 4],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colors.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i < currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
