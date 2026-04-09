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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: disabled
                ? [
                    GrowMateColors.textSecondary.withValues(alpha: 0.35),
                    GrowMateColors.textSecondary.withValues(alpha: 0.3),
                  ]
                : [GrowMateColors.primary, GrowMateColors.primaryDark],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: disabled ? 0.2 : 0.35),
          ),
          boxShadow: disabled
              ? const []
              : const [
                  BoxShadow(
                    color: GrowMateColors.shadowButton,
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
        );
      case ZenButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.white.withValues(alpha: disabled ? 0.4 : 0.72),
          border: Border.all(
            color: GrowMateColors.primary.withValues(alpha: 0.16),
          ),
          boxShadow: const [
            BoxShadow(
              color: GrowMateColors.shadowSoft,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        );
      case ZenButtonVariant.text:
        return BoxDecoration(borderRadius: radius, color: Colors.transparent);
    }
  }

  Color _textColor(bool disabled) {
    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return disabled ? Colors.white.withValues(alpha: 0.65) : Colors.white;
      case ZenButtonVariant.secondary:
        return disabled
            ? GrowMateColors.textSecondary.withValues(alpha: 0.65)
            : GrowMateColors.textPrimary;
      case ZenButtonVariant.text:
        return disabled
            ? GrowMateColors.textSecondary.withValues(alpha: 0.65)
            : GrowMateColors.primary;
    }
  }
}
