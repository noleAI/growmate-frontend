import 'package:flutter/material.dart';

import '../../../app/i18n/build_context_i18n.dart';
import '../../../core/constants/colors.dart';
import '../confidence/confidence_label.dart';

/// A thin status bar shown at the top of screens to indicate AI activity.
///
/// Auto-fades out after [autoHideDuration] and reappears when [visible] changes.
class AiWhisperBar extends StatefulWidget {
  const AiWhisperBar({
    super.key,
    this.visible = true,
    this.confidence = 0.0,
    this.statusMessage,
    this.autoHideDuration = const Duration(seconds: 3),
    this.onTap,
  });

  final bool visible;
  final double confidence;
  final String? statusMessage;
  final Duration autoHideDuration;
  final VoidCallback? onTap;

  @override
  State<AiWhisperBar> createState() => _AiWhisperBarState();
}

class _AiWhisperBarState extends State<AiWhisperBar> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant AiWhisperBar old) {
    super.didUpdateWidget(old);
    if (old.confidence != widget.confidence ||
        old.statusMessage != widget.statusMessage) {
      _hidden = false;
      _scheduleAutoHide();
    }
  }

  void _scheduleAutoHide() {
    Future.delayed(widget.autoHideDuration, () {
      if (mounted) setState(() => _hidden = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.visible && !_hidden;
    final brightness = Theme.of(context).brightness;

    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: GrowMateColors.aiWhisper(brightness)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.aiPulse(brightness),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.statusMessage ??
                    context.t(vi: 'AI đang theo dõi', en: 'AI is monitoring'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GrowMateColors.aiCore(brightness),
                ),
              ),
              if (widget.confidence > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '· ',
                  style: TextStyle(
                    fontSize: 11,
                    color: GrowMateColors.aiCore(brightness).withValues(alpha: 0.5),
                  ),
                ),
                ConfidenceLabel(
                  confidence: widget.confidence,
                  style: const TextStyle(fontSize: 11),
                  showPercentage: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
