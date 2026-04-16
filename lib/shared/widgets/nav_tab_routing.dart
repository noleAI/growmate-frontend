import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import 'bottom_nav_bar.dart';

void handleTabNavigation(BuildContext context, GrowMateTab tab) {
  switch (tab) {
    case GrowMateTab.today:
      return context.go(AppRoutes.home);
    case GrowMateTab.progress:
      return context.go(AppRoutes.progress);
    case GrowMateTab.leaderboard:
      return context.go(AppRoutes.leaderboard);
    case GrowMateTab.profile:
      return context.go(AppRoutes.profile);
    case GrowMateTab.settings:
      return context.go(AppRoutes.settings);
  }
}
