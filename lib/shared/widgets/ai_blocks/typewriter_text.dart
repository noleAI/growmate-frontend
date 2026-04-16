import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Reveals text character-by-character at a fixed pace.
///
/// Uses a [ValueNotifier] internally so only the text widget rebuilds — the
/// surrounding tree is untouched.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.msPerChar = 40,
    this.style,
    this.onComplete,
  });

  final String text;
  final int msPerChar;
  final TextStyle? style;
  final VoidCallback? onComplete;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  final _charIndex = ValueNotifier<int>(0);
  late Ticker _ticker;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _elapsedMs = elapsed.inMilliseconds;
    final target = (_elapsedMs / widget.msPerChar).floor().clamp(
      0,
      widget.text.length,
    );
    if (target != _charIndex.value) {
      _charIndex.value = target;
      if (target >= widget.text.length) {
        _ticker.stop();
        widget.onComplete?.call();
      }
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _charIndex.value = 0;
      _elapsedMs = 0;
      if (!_ticker.isActive) _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _charIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: _charIndex,
        builder: (context, idx, _) {
          return Text(
            widget.text.substring(0, idx),
            style: widget.style ?? Theme.of(context).textTheme.bodyLarge,
          );
        },
      ),
    );
  }
}
