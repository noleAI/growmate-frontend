import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  });

  final String? userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onInspectionTap;

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
    this.onNotificationTap,
    this.onInspectionTap,
  });

  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onInspectionTap;
  static final NotificationRepository _notificationRepository =
      NotificationRepository.instance;

  void _showAvatarComingSoon(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              vi: 'Tính năng avatar sẽ phát triển trong bản ra mắt sau.',
              en: 'Avatar customization will be available in a future release.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            onTap: () => _showAvatarComingSoon(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Text(
                userName.isEmpty ? 'B' : userName.substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  context.t(vi: 'Chào $userName', en: 'Hi $userName'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
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
          StreamBuilder<List<AppNotification>>(
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
          ),
        ],
      ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
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
    );
  }
}
