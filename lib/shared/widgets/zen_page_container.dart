import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
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
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -70,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(181, 220, 225, 0.55),
                    Color.fromRGBO(181, 220, 225, 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(231, 238, 214, 0.52),
                    Color.fromRGBO(231, 238, 214, 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GrowMateLayout.maxContentWidth,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.34),
                      Color.fromRGBO(255, 255, 255, 0.0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: padding,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: GrowMateColors.textPrimary),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
