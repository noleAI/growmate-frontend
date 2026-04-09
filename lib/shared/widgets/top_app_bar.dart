import 'dart:ui';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GrowMateColors.primaryContainer.withValues(
                      alpha: 0.9,
                    ),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GrowMateColors.primaryDark,
                      GrowMateColors.primary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chào $userName 👋',
                  style: const TextStyle(
                    color: GrowMateColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              if (onInspectionTap != null)
                IconButton(
                  onPressed: onInspectionTap,
                  icon: const Icon(
                    Icons.visibility_rounded,
                    color: GrowMateColors.primary,
                    size: 24,
                  ),
                ),
              IconButton(
                onPressed:
                    onNotificationTap ??
                    () {
                      context.push(AppRoutes.notifications);
                    },
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: GrowMateColors.primary,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
