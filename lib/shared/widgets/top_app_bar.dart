import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/i18n/app_language_cubit.dart';
import '../../app/i18n/build_context_i18n.dart';
import '../../app/router/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/notification/data/models/app_notification.dart';
import '../../features/notification/data/repositories/notification_repository.dart';

class GrowMateTopAppBar extends StatelessWidget {
  const GrowMateTopAppBar({
    super.key,
    this.userName,
    this.onNotificationTap,
    this.onInspectionTap,
    this.appleStyle = false,
    this.avatarNotificationOnly = false,
    this.showInsightInDev = false,
  });

  final String? userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onInspectionTap;
  final bool appleStyle;
  final bool avatarNotificationOnly;
  final bool showInsightInDev;

  @override
  Widget build(BuildContext context) {
    AuthBloc? authBloc;
    try {
      authBloc = BlocProvider.of<AuthBloc>(context);
    } catch (_) {
      authBloc = null;
    }

    if (authBloc == null) {
      return _TopAppBarBody(
        userName: _normalizeDisplayName(userName),
        onNotificationTap: onNotificationTap,
        onInspectionTap: onInspectionTap,
        appleStyle: appleStyle,
        avatarNotificationOnly: avatarNotificationOnly,
        showInsightInDev: showInsightInDev,
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: authBloc,
      buildWhen: (previous, current) {
        final previousName = previous is AuthAuthenticated
            ? previous.session.displayName
            : null;
        final currentName = current is AuthAuthenticated
            ? current.session.displayName
            : null;
        return previousName != currentName;
      },
      builder: (context, state) {
        final nameFromState = state is AuthAuthenticated
            ? state.session.displayName
            : null;

        return _TopAppBarBody(
          userName: _normalizeDisplayName(userName ?? nameFromState),
          onNotificationTap: onNotificationTap,
          onInspectionTap: onInspectionTap,
          appleStyle: appleStyle,
          avatarNotificationOnly: avatarNotificationOnly,
          showInsightInDev: showInsightInDev,
        );
      },
    );
  }

  static String _normalizeDisplayName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'User';
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ');
    final parts = compact.split(' ');
    if (parts.isEmpty) {
      return 'User';
    }

    return parts.last;
  }
}

class _TopAppBarBody extends StatelessWidget {
  const _TopAppBarBody({
    required this.userName,
    required this.appleStyle,
    required this.avatarNotificationOnly,
    required this.showInsightInDev,
    this.onNotificationTap,
    this.onInspectionTap,
  });

  final String userName;
  final bool appleStyle;
  final bool avatarNotificationOnly;
  final bool showInsightInDev;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onInspectionTap;
  static final NotificationRepository _notificationRepository =
      NotificationRepository.instance;

  Widget _buildAvatar(BuildContext context, {double size = 40}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push(AppRoutes.profile),
      child: Semantics(
        label: context.t(vi: 'Avatar tài khoản', en: 'Account avatar'),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            userName.isEmpty ? 'B' : userName.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationRepository.watchNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotification>[];
        final hasUnread = notifications.any((item) => !item.isRead);

        return _AppBarIconButton(
          onPressed:
              onNotificationTap ??
              () {
                context.push(AppRoutes.notifications);
              },
          icon: Icons.notifications_none_rounded,
          showBadge: hasUnread,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final languageSwitchWidth = screenWidth < 410 ? 96.0 : 120.0;

    if (appleStyle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _buildAvatar(context, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.t(vi: 'CHÀO MỪNG TRỞ LẠI', en: 'WELCOME BACK'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LanguageSegmentedSwitch(width: languageSwitchWidth),
            if (showInsightInDev && onInspectionTap != null) ...[
              const SizedBox(width: 6),
              _AppBarIconButton(
                onPressed: onInspectionTap,
                icon: Icons.insights_rounded,
              ),
            ],
            const SizedBox(width: 2),
            _buildNotificationButton(context),
          ],
        ),
      );
    }

    if (avatarNotificationOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _buildAvatar(context, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.t(vi: 'CHÀO MỪNG TRỞ LẠI', en: 'WELCOME BACK'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            _buildNotificationButton(context),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => context.push(AppRoutes.profile),
            child: Semantics(
              label: context.t(vi: 'Avatar tài khoản', en: 'Account avatar'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                ),
                alignment: Alignment.center,
                child: Text(
                  userName.isEmpty
                      ? 'B'
                      : userName.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GrowMate AI Tutor',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  context.t(vi: 'Chào $userName', en: 'Hi $userName'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (onInspectionTap != null)
            _AppBarIconButton(
              onPressed: onInspectionTap,
              icon: Icons.insights_rounded,
            ),
          _buildNotificationButton(context),
        ],
      ),
    );
  }
}

class _LanguageSegmentedSwitch extends StatelessWidget {
  const _LanguageSegmentedSwitch({this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final fallbackLanguage = locale.languageCode.toLowerCase().startsWith('en')
        ? AppLanguage.english
        : AppLanguage.vietnamese;

    AppLanguageCubit? languageCubit;
    try {
      languageCubit = context.read<AppLanguageCubit>();
    } catch (_) {
      languageCubit = null;
    }

    Widget buildSwitch({
      required AppLanguage language,
      required ValueChanged<AppLanguage>? onChanged,
    }) {
      Widget buildOption({required AppLanguage value, required String label}) {
        final selected = language == value;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: selected || onChanged == null
                ? null
                : () {
                    onChanged(value);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        );
      }

      return Semantics(
        label: context.t(vi: 'Chuyển ngôn ngữ', en: 'Switch language'),
        child: Container(
          width: width,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.24 : 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.36 : 0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: isDark ? 0.22 : 0.08),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              buildOption(value: AppLanguage.vietnamese, label: 'VI'),
              buildOption(value: AppLanguage.english, label: 'EN'),
            ],
          ),
        ),
      );
    }

    if (languageCubit == null) {
      return buildSwitch(language: fallbackLanguage, onChanged: null);
    }

    return BlocBuilder<AppLanguageCubit, AppLanguage>(
      bloc: languageCubit,
      builder: (context, language) {
        return buildSwitch(
          language: language,
          onChanged: (value) {
            languageCubit?.setLanguage(value);
          },
        );
      },
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.onPressed,
    required this.icon,
    this.showBadge = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNotification = icon == Icons.notifications_none_rounded;
    final semanticLabel = isNotification
        ? context.t(vi: 'Thông báo', en: 'Notifications')
        : context.t(vi: 'Kiểm tra', en: 'Inspection');

    return Semantics(
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: colors.primary, size: 19),
                ),
                if (showBadge)
                  Positioned(
                    top: 6,
                    right: 4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.surfaceContainerLow,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
