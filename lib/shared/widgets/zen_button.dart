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
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.shadowColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZenButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool expanded;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? shadowColor;

  @override
  State<ZenButton> createState() => _ZenButtonState();
}

class _ZenButtonState extends State<ZenButton> {
  static const Duration _motionDuration = Duration(milliseconds: 180);
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
              color: _textColor(disabled),
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.25,
              letterSpacing: 0.05,
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
      scale: _pressed ? 0.97 : 1,
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
          color: disabled
              ? GrowMateColors.textSecondary.withValues(alpha: 0.35)
              : (widget.backgroundColor ?? GrowMateColors.primary),
          border: Border.all(color: widget.borderColor ?? Colors.transparent),
          boxShadow: disabled
              ? const []
              : [
                  BoxShadow(
                    color: (widget.shadowColor ?? GrowMateColors.shadowButton)
                        .withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
      case ZenButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: disabled
              ? GrowMateColors.surfaceContainerHigh.withValues(alpha: 0.65)
              : (widget.backgroundColor ?? GrowMateColors.surface),
          border: Border.all(
            color:
                widget.borderColor ??
                GrowMateColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.shadowColor ?? GrowMateColors.shadowSoft)
                  .withValues(alpha: 0.75),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ZenButtonVariant.text:
        return BoxDecoration(borderRadius: radius, color: Colors.transparent);
    }
  }

  Color _textColor(bool disabled) {
    if (widget.textColor != null && !disabled) {
      return widget.textColor!;
    }

    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return disabled ? Colors.white.withValues(alpha: 0.65) : Colors.white;
      case ZenButtonVariant.secondary:
        return disabled
            ? GrowMateColors.textSecondary.withValues(alpha: 0.65)
            : GrowMateColors.primaryDark;
      case ZenButtonVariant.text:
        return disabled
            ? GrowMateColors.textSecondary.withValues(alpha: 0.65)
            : GrowMateColors.primary;
    }
  }
}
