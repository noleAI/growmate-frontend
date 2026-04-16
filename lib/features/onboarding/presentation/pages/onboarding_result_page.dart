import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Trang kết quả phân loại trình độ – bước 4/4.
class OnboardingResultPage extends StatefulWidget {
  const OnboardingResultPage({super.key});

  @override
  State<OnboardingResultPage> createState() => _OnboardingResultPageState();
}

class _OnboardingResultPageState extends State<OnboardingResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          if (state is! OnboardingComplete) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = state.result;
          final level = result.level;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Animated emoji
                  Center(
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Text(
                        level.emoji,
                        style: const TextStyle(fontSize: 96),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          context.t(vi: 'Kết quả của bạn', en: 'Your result'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          level.viLabel,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Score pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            context.t(
                              vi:
                                  '${result.correctCount}/${result.totalQuestions} câu đúng  '
                                  '(${(result.accuracy * 100).round()}%)',
                              en:
                                  '${result.correctCount}/${result.totalQuestions} correct  '
                                  '(${(result.accuracy * 100).round()}%)',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          level.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  FilledButton(
                    onPressed: () async {
                      final authState = context.read<AuthBloc>().state;
                      final userKey = authState is AuthAuthenticated
                          ? authState.session.email
                          : null;
                      await context.read<OnboardingCubit>().completeOnboarding(
                        userKey: userKey,
                      );
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.t(
                        vi: 'Vào học ngay! 🚀',
                        en: 'Start learning! 🚀',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
