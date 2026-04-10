import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ZenPageContainer(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final theme = Theme.of(context);
              final colors = theme.colorScheme;
              final isLoading = state is AuthLoading;
              final displayName = state is AuthAuthenticated
                  ? state.session.displayName
                  : context.t(vi: 'Bạn', en: 'You');
              final email = state is AuthAuthenticated
                  ? state.session.email
                  : '';

              return ListView(
                children: [
                  GrowMateTopAppBar(userName: displayName),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  Text(
                    context.t(vi: 'Hồ sơ học tập', en: 'Study profile'),
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  _ProfileBlock(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: colors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: GrowMateLayout.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: GrowMateColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: GrowMateColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  _ProfileBlock(
                    title: context.t(vi: 'Năm học / Lớp', en: 'Grade / level'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: GrowMateLayout.contentGap,
                        vertical: GrowMateLayout.space12,
                      ),
                      decoration: BoxDecoration(
                        color: GrowMateColors.backgroundSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            context.t(
                              vi: 'Đại học năm 1',
                              en: 'University year 1',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: GrowMateColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  _ProfileBlock(
                    title: context.t(
                      vi: 'Lĩnh vực học tập',
                      en: 'Learning subjects',
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SubjectChip(
                          label: context.t(vi: 'Toán', en: 'Mathematics'),
                          selected: true,
                        ),
                        _SubjectChip(
                          label: context.t(vi: 'Vật lý', en: 'Physics'),
                        ),
                        _SubjectChip(
                          label: context.t(vi: 'Hóa học', en: 'Chemistry'),
                        ),
                        _SubjectChip(
                          label: context.t(vi: 'Ngữ văn', en: 'Literature'),
                        ),
                        _SubjectChip(
                          label: context.t(vi: 'Tiếng Anh', en: 'English'),
                        ),
                        _SubjectChip(
                          label: context.t(vi: 'Sinh học', en: 'Biology'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGapLg),
                  ZenButton(
                    label: isLoading
                        ? context.t(
                            vi: 'Đang đăng xuất...',
                            en: 'Signing out...',
                          )
                        : context.t(vi: 'Đăng xuất', en: 'Log out'),
                    variant: ZenButtonVariant.secondary,
                    backgroundColor: GrowMateColors.surfaceContainerLow,
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
                                Colors.white,
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

class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: GrowMateColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GrowMateLayout.space12),
          ],
          child,
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.space12,
        vertical: GrowMateLayout.space8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? colors.primary.withValues(alpha: 0.15)
            : GrowMateColors.backgroundSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: selected ? colors.primary : GrowMateColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
