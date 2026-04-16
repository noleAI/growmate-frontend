import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _featuresController;
  late final AnimationController _ctaController;

  final List<Timer> _pendingTimers = [];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heroController.forward();
    _pendingTimers.add(
      Timer(const Duration(milliseconds: 300), () {
        if (mounted) _featuresController.forward();
      }),
    );
    _pendingTimers.add(
      Timer(const Duration(milliseconds: 550), () {
        if (mounted) _ctaController.forward();
      }),
    );
  }

  @override
  void dispose() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _heroController.dispose();
    _featuresController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: ZenPageContainer(
          child: ListView(
            children: [
              const SizedBox(height: GrowMateLayout.space12),
              // Hero card with stagger animation
              _FadeSlideWidget(
                animation: _heroController,
                child: ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 2500),
                          builder: (context, value, child) {
                            final breathe =
                                1.0 +
                                0.06 *
                                    (0.5 + 0.5 * (1 - (2 * value - 1).abs()));
                            return Transform.scale(
                              scale: breathe,
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.energy_savings_leaf_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: GrowMateLayout.sectionGap),
                      Text(
                        context.t(
                          vi: 'Chào bạn đến với GrowMate',
                          en: 'Welcome to GrowMate',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: GrowMateLayout.space16),
                      Text(
                        context.t(
                          vi: 'Học nhẹ hơn, đều hơn, và vẫn hiệu quả từng ngày.',
                          en: 'Study gently, stay consistent, and keep improving every day.',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.space16),

              // Feature highlights with stagger animation
              _FadeSlideWidget(
                animation: _featuresController,
                child: ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FeatureHighlight(
                        icon: Icons.auto_awesome_rounded,
                        text: context.t(
                          vi: 'AI cá nhân hóa lộ trình học',
                          en: 'AI personalized learning path',
                        ),
                        color: theme.colorScheme.primary,
                      ),
                      _FeatureHighlight(
                        icon: Icons.quiz_rounded,
                        text: context.t(
                          vi: 'Luyện đề THPT Toán 2026',
                          en: 'THPT Math 2026 practice',
                        ),
                        color: theme.colorScheme.tertiary,
                      ),
                      _FeatureHighlight(
                        icon: Icons.insights_rounded,
                        text: context.t(
                          vi: 'Phân tích điểm mạnh & yếu',
                          en: 'Strengths & weaknesses analysis',
                        ),
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.space16),

              // CTA buttons with stagger animation
              _FadeSlideWidget(
                animation: _ctaController,
                child: ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ZenButton(
                        label: context.t(vi: 'Đăng nhập', en: 'Log in'),
                        onPressed: () => context.push(AppRoutes.login),
                      ),
                      const SizedBox(height: 12),
                      ZenButton(
                        label: context.t(
                          vi: 'Tạo tài khoản',
                          en: 'Create account',
                        ),
                        variant: ZenButtonVariant.secondary,
                        onPressed: () => context.push(AppRoutes.register),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.space16),
              // Motivational footer with CTA animation
              _FadeSlideWidget(
                animation: _ctaController,
                child: Text(
                  context.t(
                    vi: 'Mỗi phiên học chỉ cần một nhịp nhỏ, bạn đang làm rất tốt rồi.',
                    en: 'Each study session only needs a small step, and you are doing great.',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeSlideWidget extends StatelessWidget {
  const _FadeSlideWidget({required this.animation, required this.child});

  final AnimationController animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  const _FeatureHighlight({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
