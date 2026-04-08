import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class GrowMateTopAppBar extends StatelessWidget {
  const GrowMateTopAppBar({
    super.key,
    this.userName = 'Lan Anh',
    this.onNotificationTap,
  });

  final String userName;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GrowMateColors.primaryContainer.withValues(alpha: 0.75),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF101826),
                      Color(0xFF455D9A),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotificationTap,
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