import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../pages/roadmap_learning_data.dart';

/// Stat of each roadmap node.
enum RoadmapNodeState { locked, available, inProgress, completed }

/// Data for a single rendered node on the graph.
class _NodeData {
  const _NodeData({
    required this.subject,
    required this.topic,
    required this.subtopicCount,
    required this.nodeState,
    required this.index,
    this.isFirstInSubject = false,
  });

  final RoadmapSubject subject;
  final RoadmapTopic topic;
  final int subtopicCount;
  final RoadmapNodeState nodeState;
  final int index;
  final bool isFirstInSubject;
}

/// Duolingo-style node graph for a learning roadmap.
///
/// Subjects → Topics are rendered as tappable circular nodes arranged
/// in a staggered zigzag path, connected by animated arc lines.
/// A glowing ring marks the active in-progress node.
class SubjectNodeGraph extends StatefulWidget {
  const SubjectNodeGraph({
    super.key,
    required this.subjects,
    this.completedPercent = 0.35,
    this.onNodeTap,
  });

  final List<RoadmapSubject> subjects;

  /// Overall completion 0.0–1.0 (used to decide node states).
  final double completedPercent;

  final void Function(RoadmapSubject subject, RoadmapTopic topic)? onNodeTap;

  @override
  State<SubjectNodeGraph> createState() => _SubjectNodeGraphState();
}

class _SubjectNodeGraphState extends State<SubjectNodeGraph>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _nodeRadius = 32.0;
  static const _zoneHeight = 120.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_NodeData> _buildNodes() {
    final nodes = <_NodeData>[];
    int i = 0;
    for (final subject in widget.subjects) {
      for (final topic in subject.topics) {
        final fraction =
            i /
            (widget.subjects.fold<int>(0, (sum, s) => sum + s.topics.length));
        final RoadmapNodeState state;
        if (fraction < widget.completedPercent - 0.15) {
          state = RoadmapNodeState.completed;
        } else if (fraction < widget.completedPercent) {
          state = RoadmapNodeState.inProgress;
        } else if (fraction < widget.completedPercent + 0.2) {
          state = RoadmapNodeState.available;
        } else {
          state = RoadmapNodeState.locked;
        }
        nodes.add(
          _NodeData(
            subject: subject,
            topic: topic,
            subtopicCount: topic.subtopics.length,
            nodeState: state,
            index: i,
            isFirstInSubject: topic == subject.topics.first,
          ),
        );
        i++;
      }
    }
    return nodes;
  }

  /// Zigzag layout: alternate left/center/right columns.
  Offset _positionFor(int index, double availableWidth) {
    final columns = [0.25, 0.5, 0.75];
    final col = columns[index % 3];
    final x = availableWidth * col;
    final y = _zoneHeight * index + _nodeRadius + 16;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _buildNodes();
    final totalHeight = _zoneHeight * nodes.length + _nodeRadius * 2 + 32;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final positions = [
          for (var i = 0; i < nodes.length; i++) _positionFor(i, width),
        ];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: width,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Connection lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PathPainter(
                      positions: positions,
                      nodes: nodes,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      trackColor: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                // Node circles + labels
                for (var i = 0; i < nodes.length; i++)
                  _NodeWidget(
                    node: nodes[i],
                    position: positions[i],
                    radius: _nodeRadius,
                    pulseAnimation: _pulseAnimation,
                    onTap: widget.onNodeTap == null
                        ? null
                        : () => widget.onNodeTap!(
                            nodes[i].subject,
                            nodes[i].topic,
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Path painter ─────────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.positions,
    required this.nodes,
    required this.primaryColor,
    required this.trackColor,
  });

  final List<Offset> positions;
  final List<_NodeData> nodes;
  final Color primaryColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    for (var i = 0; i < positions.length - 1; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      final fromState = nodes[i].nodeState;
      final toState = nodes[i + 1].nodeState;

      final isActive =
          fromState == RoadmapNodeState.completed ||
          fromState == RoadmapNodeState.inProgress;
      final color = isActive
          ? primaryColor.withValues(alpha: 0.5)
          : trackColor.withValues(alpha: 0.8);

      final paint = Paint()
        ..color = color
        ..strokeWidth = isActive ? 2.5 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isActive) {
        paint.shader = LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.7),
            primaryColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(from, to));
      }

      // Bezier curve between nodes for organic feeling
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final cp = Offset(from.dx, mid.dy);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(cp.dx, cp.dy, to.dx, to.dy);

      // Dashes for locked segments
      if (toState == RoadmapNodeState.locked) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.positions != positions ||
      old.nodes != nodes ||
      old.primaryColor != primaryColor;
}

// ── Node widget ───────────────────────────────────────────────────────────────

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({
    required this.node,
    required this.position,
    required this.radius,
    required this.pulseAnimation,
    this.onTap,
  });

  final _NodeData node;
  final Offset position;
  final double radius;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  Color _fillColor(BuildContext context) {
    switch (node.nodeState) {
      case RoadmapNodeState.completed:
        return const Color(0xFF22C55E);
      case RoadmapNodeState.inProgress:
        return Theme.of(context).colorScheme.primary;
      case RoadmapNodeState.available:
        return Theme.of(context).colorScheme.surface;
      case RoadmapNodeState.locked:
        return Theme.of(context).colorScheme.surfaceContainerHigh;
    }
  }

  Color _borderColor(BuildContext context) {
    switch (node.nodeState) {
      case RoadmapNodeState.completed:
        return const Color(0xFF22C55E);
      case RoadmapNodeState.inProgress:
        return Theme.of(context).colorScheme.primary;
      case RoadmapNodeState.available:
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.45);
      case RoadmapNodeState.locked:
        return Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);
    }
  }

  IconData _icon() {
    switch (node.nodeState) {
      case RoadmapNodeState.completed:
        return Icons.check_rounded;
      case RoadmapNodeState.inProgress:
        return Icons.play_arrow_rounded;
      case RoadmapNodeState.available:
        return Icons.star_outline_rounded;
      case RoadmapNodeState.locked:
        return Icons.lock_outline_rounded;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (node.nodeState) {
      case RoadmapNodeState.completed:
        return Colors.white;
      case RoadmapNodeState.inProgress:
        return Colors.white;
      case RoadmapNodeState.available:
        return Theme.of(context).colorScheme.primary;
      case RoadmapNodeState.locked:
        return Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = node.nodeState == RoadmapNodeState.inProgress;
    final isLocked = node.nodeState == RoadmapNodeState.locked;

    // Label side: alternate to avoid overlap
    final labelOnRight = node.index % 2 != 1;

    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!labelOnRight) ...[
                _NodeLabel(node: node, alignRight: true, isLocked: isLocked),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: isLocked ? null : onTap,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    final glowRadius = isActive
                        ? 4.0 + pulseAnimation.value * 6.0
                        : 0.0;
                    return Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _fillColor(context),
                        border: Border.all(
                          color: _borderColor(context),
                          width: isActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(
                                        alpha:
                                            0.35 + pulseAnimation.value * 0.2,
                                      ),
                                  blurRadius: glowRadius * 2,
                                  spreadRadius: glowRadius * 0.5,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _icon(),
                        size: 20,
                        color: _iconColor(context),
                      ),
                    );
                  },
                ),
              ),
              if (labelOnRight) ...[
                const SizedBox(width: 8),
                _NodeLabel(node: node, alignRight: false, isLocked: isLocked),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({
    required this.node,
    required this.alignRight,
    required this.isLocked,
  });

  final _NodeData node;
  final bool alignRight;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (node.isFirstInSubject) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                node.subject.title,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            node.topic.title,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isLocked
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                  : theme.colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          Text(
            context.t(
              vi: '${node.subtopicCount} bài',
              en: '${node.subtopicCount} lessons',
            ),
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: isLocked
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                  : primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
