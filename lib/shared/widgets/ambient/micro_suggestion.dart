import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/layout.dart';

/// Small dismissible chip for contextual AI micro-suggestions.
///
/// Examples: "Buổi sáng phù hợp ôn lại", "3 ngày rồi — bắt đầu nhẹ?"
class MicroSuggestion extends StatefulWidget {
  const MicroSuggestion({
    super.key,
    required this.text,
    this.onTap,
    this.onDismiss,
  });

  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  State<MicroSuggestion> createState() => _MicroSuggestionState();
}

class _MicroSuggestionState extends State<MicroSuggestion>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: GrowMateLayout.horizontalPadding,
            vertical: 6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: GrowMateColors.aiWhisper(brightness),
            borderRadius: BorderRadius.circular(GrowMateLayout.cardRadiusSm),
            border: Border.all(
              color: GrowMateColors.aiCore(brightness).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.aiCore(brightness),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GrowMateColors.aiCore(brightness),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: GrowMateColors.aiCore(brightness).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
