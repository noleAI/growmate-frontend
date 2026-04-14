import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/study_mode.dart';

/// Trang chọn chế độ học trước khi vào quiz.
///
/// 2 card lớn: 🎓 Luyện thi / 🎮 Trải nghiệm.
/// Returns selected [StudyMode] via Navigator pop.
class ModeSelectionPage extends StatefulWidget {
  const ModeSelectionPage({super.key, this.currentMode});

  final StudyMode? currentMode;

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage> {
  StudyMode? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                context.t(vi: 'Chọn chế độ học', en: 'Choose Study Mode'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.t(
                  vi: 'Bạn có thể đổi lại bất cứ lúc nào trong Cài đặt.',
                  en: 'You can change this anytime in Settings.',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ModeCard(
                icon: Icons.school_rounded,
                emoji: '🎓',
                title: context.t(vi: 'Luyện thi', en: 'Exam Prep'),
                subtitle: context.t(
                  vi: 'Như đề thi thật',
                  en: 'Like a real exam',
                ),
                features: [
                  context.t(
                    vi: '⏱  Bấm giờ mỗi câu',
                    en: '⏱  Timed per question',
                  ),
                  context.t(vi: '📊  Chấm điểm chặt', en: '📊  Strict scoring'),
                  context.t(vi: '🔒  Gợi ý hạn chế', en: '🔒  Limited hints'),
                ],
                isSelected: _selected == StudyMode.examPrep,
                accentColor: colors.primary,
                onTap: () => setState(() => _selected = StudyMode.examPrep),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.sports_esports_rounded,
                emoji: '🎮',
                title: context.t(vi: 'Trải nghiệm', en: 'Casual'),
                subtitle: context.t(
                  vi: 'Học nhẹ, không áp lực',
                  en: 'Learn stress-free',
                ),
                features: [
                  context.t(
                    vi: '🕐  Không giới hạn thời gian',
                    en: '🕐  No time limit',
                  ),
                  context.t(
                    vi: '💡  Xem gợi ý thoải mái',
                    en: '💡  Unlimited hints',
                  ),
                  context.t(
                    vi: '🌱  Tập trung hiểu bài',
                    en: '🌱  Focus on understanding',
                  ),
                ],
                isSelected: _selected == StudyMode.casual,
                accentColor: colors.tertiary,
                onTap: () => setState(() => _selected = StudyMode.casual),
              ),
              const Spacer(),
              ZenButton(
                label: context.t(vi: 'Tiếp tục', en: 'Continue'),
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : colors.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  feature,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
