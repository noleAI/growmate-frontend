import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthError,
      listener: (context, state) {
        if (state is! AuthError) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: GrowMateColors.surfaceContainerHigh,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
        backgroundColor: GrowMateColors.background,
        body: ZenPageContainer(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final theme = Theme.of(context);
              final isLoading = state is AuthLoading;
              final displayName = state is AuthAuthenticated
                  ? state.session.displayName
                  : 'Bạn';
              final email = state is AuthAuthenticated
                  ? state.session.email
                  : '';

              return ListView(
                children: [
                  GrowMateTopAppBar(userName: displayName),
                  const SizedBox(height: 28),
                  ZenCard(
                    radius: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ sơ học tập',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chào $displayName, bạn đang duy trì nhịp học rất tốt. Mình sẽ cá nhân hóa lộ trình sâu hơn theo tiến trình của bạn.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: GrowMateColors.textSecondary,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: const TextStyle(
                              color: GrowMateColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ZenButton(
                          label: isLoading ? 'Đang đăng xuất...' : 'Đăng xuất',
                          variant: ZenButtonVariant.secondary,
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                    const LogoutRequested(),
                                  );
                                },
                          trailing: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      GrowMateColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_rounded,
                                  color: GrowMateColors.textPrimary,
                                  size: 22,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: GrowMateBottomNavBar(
          currentTab: GrowMateTab.profile,
          onTabSelected: (tab) => handleTabNavigation(context, tab),
        ),
      ),
    );
  }
}
