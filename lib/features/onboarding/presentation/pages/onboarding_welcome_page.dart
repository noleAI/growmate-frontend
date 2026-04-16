import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../cubit/onboarding_cubit.dart';

/// Trang chào mừng – bước 1/4 onboarding.
/// Cubit được cung cấp từ ShellRoute cha.
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WelcomeBody();
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Animated hero illustration
              Center(child: _AnimatedPlantHero()),
              const SizedBox(height: 32),
              Text(
                context.t(
                  vi: 'Chào mừng đến với GrowMate!',
                  en: 'Welcome to GrowMate!',
                ),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.t(
                  vi:
                      'Hãy để chúng mình giúp bạn học toán thật hiệu quả. '
                      'Chỉ mất 2 phút để cá nhân hoá lộ trình học của bạn!',
                  en:
                      'Let us help you learn math effectively. '
                      'It only takes 2 minutes to personalize your learning path!',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // CTA button
              FilledButton(
                onPressed: () => context.push(AppRoutes.onboardingGoal),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.t(vi: 'Bắt đầu nào! →', en: 'Let\'s go! →'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _confirmSkip(context),
                child: Text(
                  context.t(vi: 'Bỏ qua', en: 'Skip'),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;

    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.t(vi: 'Bỏ qua onboarding?', en: 'Skip onboarding?'),
        ),
        content: Text(
          context.t(
            vi:
                'AI sẽ không tối ưu được lộ trình học cho bạn. '
                'Bạn có thể làm lại trong Cài đặt.',
            en:
                'AI won\'t be able to optimize your learning path. '
                'You can redo this in Settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              context.t(vi: 'Ở lại', en: 'Stay'),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t(vi: 'Bỏ qua', en: 'Skip')),
          ),
        ],
      ),
    );

    if (shouldSkip == true && context.mounted) {
      final authState = context.read<AuthBloc>().state;
      final userKey = authState is AuthAuthenticated
          ? authState.session.email
          : null;
      await context.read<OnboardingCubit>().completeOnboarding(
        userKey: userKey,
      );
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}

/// Animated plant illustration replacing the plain emoji.
class _AnimatedPlantHero extends StatefulWidget {
  @override
  State<_AnimatedPlantHero> createState() => _AnimatedPlantHeroState();
}

class _AnimatedPlantHeroState extends State<_AnimatedPlantHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.primaryContainer,
                colors.primary.withValues(alpha: 0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text('🌱', style: const TextStyle(fontSize: 64)),
          ),
        ),
      ),
    );
  }
}
