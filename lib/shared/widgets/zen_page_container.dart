import 'package:flutter/material.dart';

import '../../core/constants/layout.dart';

class ZenPageContainer extends StatelessWidget {
  const ZenPageContainer({
    super.key,
    required this.child,
    this.padding = GrowMateLayout.pagePadding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GrowMateLayout.maxContentWidth,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
