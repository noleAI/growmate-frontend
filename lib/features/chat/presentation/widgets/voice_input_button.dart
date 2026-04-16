import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Voice input button for the chat — long-press to start listening.
///
/// Requires `speech_to_text` package to be wired up.
/// Currently shows a placeholder state since STT is not yet integrated.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({super.key, required this.onResult});

  final ValueChanged<String> onResult;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    // TODO: Wire up speech_to_text package
    // For now, simulate after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _stopListening();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              vi: 'Nhận dạng giọng nói chưa sẵn sàng',
              en: 'Voice recognition not yet available',
            ),
          ),
        ),
      );
    });
  }

  void _stopListening() {
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isListening
              ? 1.0 + _pulseController.value * 0.15
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? theme.colorScheme.error
                    : theme.colorScheme.primaryContainer,
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
