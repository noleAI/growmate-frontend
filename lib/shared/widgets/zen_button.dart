import 'package:flutter/material.dart';

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
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
  static const Duration _motionDuration = Duration(milliseconds: 200);
  bool _pressed = false;
  bool _hovered = false;

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

    Widget child = AnimatedScale(
      scale: _pressed ? 0.985 : (_hovered && !disabled ? 1.005 : 1),
      duration: _motionDuration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _motionDuration,
        curve: Curves.easeOut,
        width: widget.expanded ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 52),
        padding: widget.padding,
        decoration: _decoration(disabled),
        child: _buildContent(disabled),
      ),
    );

    if (disabled) {
      child = Semantics(
        label: widget.label,
        excludeSemantics: true,
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapUp: disabled ? null : (_) => _setPressed(false),
      onTapCancel: disabled ? null : () => _setPressed(false),
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) {
          if (disabled || _hovered) {
            return;
          }
          setState(() {
            _hovered = true;
          });
        },
        onExit: (_) {
          if (!_hovered) {
            return;
          }
          setState(() {
            _hovered = false;
          });
        },
        child: child,
      ),
    );
  }

  Widget _buildContent(bool disabled) {
    final isLoading = widget.trailing is SizedBox;
    final semanticsLabel = isLoading && disabled ? widget.label : null;

    Widget content = Row(
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
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 1.25,
              letterSpacing: 0.02,
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

    if (semanticsLabel != null) {
      return Semantics(label: semanticsLabel, child: content);
    }

    return content;
  }

  BoxDecoration _decoration(bool disabled) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(GrowMateLayout.buttonRadius);

    switch (widget.variant) {
      case ZenButtonVariant.primary:
        final primaryHsl = HSLColor.fromColor(theme.colorScheme.primary);
        final darkerPrimary = primaryHsl
            .withLightness(
              (primaryHsl.lightness - 0.12).clamp(0.0, 1.0).toDouble(),
            )
            .toColor();

        final defaultGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, darkerPrimary],
        );

        return BoxDecoration(
          borderRadius: radius,
          color: disabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
              : widget.backgroundColor,
          gradient: disabled || widget.backgroundColor != null
              ? null
              : defaultGradient,
          border: Border.all(color: Colors.transparent),
          boxShadow: disabled
              ? const []
              : [
                  BoxShadow(
                    color:
                        (widget.shadowColor ??
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ))
                            .withValues(alpha: _hovered ? 0.16 : 0.12),
                    blurRadius: _hovered ? 24 : 20,
                    offset: Offset(0, _hovered ? 10 : 8),
                  ),
                ],
        );
      case ZenButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: disabled
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
              : (widget.backgroundColor ??
                    theme.colorScheme.surfaceContainerHigh),
          border: Border.all(color: widget.borderColor ?? Colors.transparent),
          boxShadow: const [],
        );
      case ZenButtonVariant.text:
        return BoxDecoration(borderRadius: radius, color: Colors.transparent);
    }
  }

  Color _textColor(bool disabled) {
    final theme = Theme.of(context);

    if (widget.textColor != null && !disabled) {
      return widget.textColor!;
    }

    switch (widget.variant) {
      case ZenButtonVariant.primary:
        return disabled
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.65)
            : theme.colorScheme.onPrimary;
      case ZenButtonVariant.secondary:
        return disabled
            ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
            : theme.colorScheme.onSurface;
      case ZenButtonVariant.text:
        return disabled
            ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
            : theme.colorScheme.primary;
    }
  }
}
