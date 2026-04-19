import 'package:flutter/material.dart';

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<String> _stages = <String>[
    'Đang đọc câu hỏi của bạn',
    'Đang đối chiếu kiến thức phù hợp',
    'Đang soạn câu trả lời dễ hiểu',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stageIndex = (_controller.value * _stages.length)
        .floor()
        .clamp(0, _stages.length - 1)
        .toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GrowMate đang trả lời',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stages[stageIndex],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final t = (_controller.value - delay).clamp(0.0, 1.0);
                        final bounce = (t < 0.5) ? 4.0 * t * (1 - t) * 4 : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Transform.translate(
                            offset: Offset(0, -bounce),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
