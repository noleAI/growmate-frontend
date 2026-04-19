import 'package:flutter/material.dart';
import '../../features/mascot/presentation/pages/mascot_selection_page.dart';

/// Simple mascot widget for home page (shows selected or default mascot)
class ZenMascot extends StatelessWidget {
  final MascotId mascotId;
  final double size;
  const ZenMascot({super.key, required this.mascotId, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot.all.firstWhere(
      (m) => m.id == mascotId,
      orElse: () => Mascot.all.first,
    );
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    // Default to the cheerful mood until session-driven mascot state is wired in.
    final mood = mascot.moods.happy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(mood, style: TextStyle(fontSize: size)),
        const SizedBox(height: 8),
        Text(
          isEnglish ? mascot.enName : mascot.viName,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
