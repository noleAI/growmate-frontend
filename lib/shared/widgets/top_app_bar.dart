import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

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
      return 'Bạn';
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ');
    final parts = compact.split(' ');
    if (parts.isEmpty) {
      return 'Bạn';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GrowMateColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: GrowMateColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GrowMate AI Tutor',
                  style: TextStyle(
                    color: GrowMateColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Chào $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GrowMateColors.textPrimary,
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
          _AppBarIconButton(
            onPressed:
                onNotificationTap ??
                () {
                  context.push(AppRoutes.notifications);
                },
            icon: Icons.notifications_none_rounded,
            showBadge: true,
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
                  color: GrowMateColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: GrowMateColors.primary, size: 19),
              ),
              if (showBadge)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: GrowMateColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GrowMateColors.surfaceContainerLow,
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
