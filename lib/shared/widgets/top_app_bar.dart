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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: GrowMateColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GrowMateColors.primaryContainer,
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: GrowMateColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GrowMate AI Tutor',
                  style: TextStyle(
                    color: GrowMateColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chào $userName',
                  style: const TextStyle(
                    color: GrowMateColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (onInspectionTap != null)
            IconButton(
              onPressed: onInspectionTap,
              icon: const Icon(
                Icons.insights_rounded,
                color: GrowMateColors.primary,
                size: 22,
              ),
            ),
          IconButton(
            onPressed:
                onNotificationTap ??
                () {
                  context.push(AppRoutes.notifications);
                },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: GrowMateColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
