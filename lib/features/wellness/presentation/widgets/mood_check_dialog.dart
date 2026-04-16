import 'package:flutter/material.dart';

import '../../../../../app/i18n/build_context_i18n.dart';
import '../../../../../core/constants/layout.dart';

enum MoodType {
  happy('😊', 'Vui vẻ', 'Happy'),
  neutral('😐', 'Bình thường', 'Neutral'),
  anxious('😰', 'Lo lắng', 'Anxious'),
  frustrated('😤', 'Bực bội', 'Frustrated'),
  tired('😴', 'Mệt mỏi', 'Tired');

  const MoodType(this.emoji, this.viLabel, this.enLabel);

  final String emoji;
  final String viLabel;
  final String enLabel;
}

class MoodCheckDialog extends StatelessWidget {
  const MoodCheckDialog({super.key, required this.onMoodSelected});

  final ValueChanged<MoodType> onMoodSelected;

  static Future<MoodType?> show(BuildContext context) {
    return showDialog<MoodType>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MoodCheckDialog(
        onMoodSelected: (mood) => Navigator.of(context).pop(mood),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t(
                vi: 'Hôm nay bạn cảm thấy thế nào?',
                en: 'How are you feeling today?',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((mood) {
                return _MoodButton(
                  mood: mood,
                  onTap: () => onMoodSelected(mood),
                );
              }).toList(),
            ),
            const SizedBox(height: GrowMateLayout.space12),
          ],
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.mood, required this.onTap});

  final MoodType mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              context.t(vi: mood.viLabel, en: mood.enLabel),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
