import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';

import '../../../../app/router/app_routes.dart';
import '../../data/models/onboarding_models.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Trang chọn mục tiêu học – bước 2/4.
class OnboardingGoalPage extends StatefulWidget {
  const OnboardingGoalPage({super.key});

  @override
  State<OnboardingGoalPage> createState() => _OnboardingGoalPageState();
}

class _OnboardingGoalPageState extends State<OnboardingGoalPage> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingCubit>().loadGoalSelection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.onboarding);
            }
          },
        ),
      ),
      body: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingQuizInProgress) {
            context.push(AppRoutes.onboardingQuiz);
          }
        },
        builder: (context, state) {
          if (state is OnboardingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OnboardingGoalSelection) {
            return _GoalBody(state: state);
          }
          if (state is OnboardingError) {
            return Center(
              child: Text(
                'Lỗi: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _GoalBody extends StatelessWidget {
  const _GoalBody({required this.state});

  final OnboardingGoalSelection state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<OnboardingCubit>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Progress indicator
            _StepIndicator(currentStep: 2, totalSteps: 4),
            const SizedBox(height: 24),
            Text(
              context.t(
                vi: 'Mục tiêu của bạn là gì?',
                en: 'What is your goal?',
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                vi: 'Chọn mục tiêu để GrowMate tạo lộ trình phù hợp nhất cho bạn.',
                en: 'Choose a goal so GrowMate can create the best learning path for you.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Goal cards
            Expanded(
              child: ListView.separated(
                itemCount: state.goals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final goal = state.goals[i];
                  final isSelected = state.selectedGoalId == goal.id;
                  return _GoalCard(
                    goal: goal,
                    isSelected: isSelected,
                    onTap: () => cubit.selectGoal(goal.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _DailyMinutesCard(
              dailyMinutes: state.selectedDailyMinutes,
              onChanged: cubit.selectDailyMinutes,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.selectedGoalId != null
                  ? () => cubit.startDiagnosticQuiz()
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.t(vi: 'Tiếp theo →', en: 'Next →'),
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final StudyGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyMinutesCard extends StatelessWidget {
  const _DailyMinutesCard({
    required this.dailyMinutes,
    required this.onChanged,
  });

  final int dailyMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t(vi: 'Thời lượng học mỗi ngày', en: 'Daily study time'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              vi: 'GrowMate sẽ dựa vào mốc này để gợi ý lộ trình phù hợp.',
              en: 'GrowMate uses this target to suggest a suitable study plan.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$dailyMinutes ${context.t(vi: 'phút/ngày', en: 'min/day')}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: dailyMinutes.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            label: '$dailyMinutes',
            onChanged: (value) {
              final stepped = ((value / 5).round() * 5).clamp(5, 180).toInt();
              onChanged(stepped);
            },
          ),
        ],
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
            margin: const EdgeInsets.symmetric(horizontal: 3),
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
