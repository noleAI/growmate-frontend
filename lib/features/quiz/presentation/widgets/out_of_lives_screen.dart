import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../cubit/lives_cubit.dart';
import '../cubit/lives_state.dart';

/// Màn hình hết tim — block quiz và hiện countdown hồi sinh.
class OutOfLivesScreen extends StatelessWidget {
  const OutOfLivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💔', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.t(vi: 'Hết tim rồi!', en: 'No lives left!'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.t(
                  vi: 'Bạn đã dùng hết tim hôm nay.\nNghỉ ngơi chút rồi quay lại nhé 😊',
                  en: 'You\'ve used all your lives today.\nRest a bit and come back soon 😊',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Countdown
              BlocBuilder<LivesCubit, LivesState>(
                builder: (context, state) {
                  if (state is LivesLoaded && state.countdownDisplay != null) {
                    return Column(
                      children: [
                        Text(
                          context.t(vi: '⏰ Hồi sinh trong', en: '⏰ Regen in'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            state.countdownDisplay!,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onPrimaryContainer,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 36),
              // CTA Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.spacedReview),
                  icon: const Icon(Icons.book_outlined),
                  label: Text(
                    context.t(vi: 'Xem lại bài sai', en: 'Review mistakes'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(
                    context.t(vi: 'Về Trang chủ', en: 'Back to Home'),
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
