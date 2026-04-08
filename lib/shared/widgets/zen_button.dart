import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';

enum ZenButtonVariant { primary, secondary, text }

class ZenButton extends StatefulWidget {
  const ZenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ZenButtonVariant.primary,
    this.leading,
    this.trailing,
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  final String label;
  final VoidCallback? onPressed;
  final ZenButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool expanded;
  final EdgeInsets padding;

  @override
  State<ZenButton> createState() => _ZenButtonState();
}

class _ZenButtonState extends State<ZenButton> {
  static const Duration _motionDuration = Duration(milliseconds: 260);
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    final baseChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textColor(),
              fontWeight: FontWeight.w700,
              fontSize: 19,
              height: 1.2,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 10),
          widget.trailing!,
        ],
      ],
    );

    final body = AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: _motionDuration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _motionDuration,
        curve: Curves.easeOut,
        width: widget.expanded ? double.infinity : null,
        padding: widget.padding,
        decoration: _decoration(disabled),
        child: baseChild,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapUp: disabled ? null : (_) => _setPressed(false),
      onTapCancel: disabled ? null : () => _setPressed(false),
      onTap: widget.onPressed,
      child: body,
    );
  }

  BoxDecoration _decoration(bool disabled) {
    final radius = BorderRadius.circular(GrowMateLayout.buttonRadius);

    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GrowMateColors.primary, GrowMateColors.primaryDark],
          ),
          boxShadow: disabled
              ? const []
              : const [
                  BoxShadow(
                    color: GrowMateColors.shadowButton,
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
        );
      case ZenButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: GrowMateColors.surfaceContainerLow,
          boxShadow: const [
            BoxShadow(
              color: GrowMateColors.shadowSoft,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        );
      case ZenButtonVariant.text:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.transparent,
        );
    }
  }

  Color _textColor() {
    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return Colors.white;
      case ZenButtonVariant.secondary:
      case ZenButtonVariant.text:
        return GrowMateColors.textPrimary;
    }
  }
}