import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';

class ZenPageContainer extends StatelessWidget {
  const ZenPageContainer({
    super.key,
    required this.child,
    this.padding = GrowMateLayout.pagePadding,
    this.includeBottomSafeArea = true,
    this.includeTopPadding = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool includeBottomSafeArea;
  final bool includeTopPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final effectivePadding = resolvedPadding.copyWith(
      top: includeTopPadding ? resolvedPadding.top : 0,
      bottom: includeBottomSafeArea ? resolvedPadding.bottom : 0,
    );

    return SafeArea(
      bottom: includeBottomSafeArea,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (notification) {
          notification.disallowIndicator();
          return false;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GrowMateLayout.maxContentWidth,
            ),
            child: Padding(
              padding: effectivePadding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: theme.colorScheme.onSurface),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
