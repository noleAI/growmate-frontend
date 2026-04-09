import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../inspection/presentation/cubit/inspection_cubit.dart';
import '../../../inspection/presentation/widgets/inspection_bottom_sheet.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/top_app_bar.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: GrowMateColors.background,
      body: ZenPageContainer(
        child: ListView(
          children: [
            _buildTopAppBar(context),
            const SizedBox(height: 18),
            Text(
              _vnDateLabel(DateTime.now()),
              style: const TextStyle(
                color: GrowMateColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mọi thứ đã sẵn sàng cho\nmột ngày mới nhẹ\nnhàng.',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 36,
                height: 1.14,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(height: 20),
            ZenCard(
              radius: 34,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBFCFA), Color(0xFFF4F1EA)],
              ),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD9ECEF), Color(0xFFC2E0E6)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: GrowMateColors.primary,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Hôm nay mình học nhẹ\nphần Đạo hàm nhé 😊',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      height: 1.26,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 220,
                    child: ZenButton(
                      label: 'Bắt đầu',
                      onPressed: () => context.push(AppRoutes.quiz),
                      expanded: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: GrowMateColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: GrowMateColors.success,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Dự kiến: 15 phút',
                      style: TextStyle(
                        color: GrowMateColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'GỢI Ý KHÁC',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GrowMateColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.65,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: const [
                _SoftChip(
                  icon: Icons.psychology_alt_rounded,
                  label: 'Luyện tập tư duy',
                ),
                _SoftChip(icon: Icons.eco_rounded, label: 'Nghỉ ngơi 5p'),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB8D5D9),
                    Color(0xFFD2E3E4),
                    Color(0xFFEDEFE9),
                  ],
                ),
              ),
              child: Stack(
                children: const [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(34)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 132,
                      color: Color(0xFF9AA8A5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.today,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    InspectionCubit? inspectionCubit;

    try {
      inspectionCubit = BlocProvider.of<InspectionCubit>(context);
    } catch (_) {
      inspectionCubit = null;
    }

    if (inspectionCubit == null) {
      return const GrowMateTopAppBar();
    }

    return StreamBuilder<InspectionState>(
      stream: inspectionCubit.stream,
      initialData: inspectionCubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? inspectionCubit!.state;

        return GrowMateTopAppBar(
          onInspectionTap: state.canInspect
              ? () {
                  InspectionBottomSheet.show(context);
                }
              : null,
        );
      },
    );
  }

  static String _vnDateLabel(DateTime now) {
    const weekdays = <int, String>{
      1: 'THỨ HAI',
      2: 'THỨ BA',
      3: 'THỨ TƯ',
      4: 'THỨ NĂM',
      5: 'THỨ SÁU',
      6: 'THỨ BẢY',
      7: 'CHỦ NHẬT',
    };
    final weekday = weekdays[now.weekday] ?? 'THỨ';
    return '$weekday, ${now.day} THÁNG ${now.month}';
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: GrowMateColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: GrowMateColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: GrowMateColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
