import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import 'bottom_nav_bar.dart';

void handleTabNavigation(BuildContext context, GrowMateTab tab) {
  switch (tab) {
    case GrowMateTab.today:
      context.go(AppRoutes.home);
    case GrowMateTab.progress:
      context.go(AppRoutes.progress);
    case GrowMateTab.profile:
      context.go(AppRoutes.profile);
  }
}