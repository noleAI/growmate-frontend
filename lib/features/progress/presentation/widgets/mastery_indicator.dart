import 'package:flutter/material.dart';

/// Chỉ báo mức độ thuộc công thức.
///
/// - null accuracy → "Chưa làm" (xám)
/// - < 0.4         → "Chưa thuộc" (đỏ)
/// - 0.4 – 0.79    → "Đang học" (vàng)
/// - ≥ 0.8         → "Đã thuộc" (xanh)
class MasteryIndicator extends StatelessWidget {
  const MasteryIndicator({super.key, this.accuracy, this.compact = false});

  final double? accuracy;

  /// Nếu true chỉ hiện dot, không hiện text.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _resolve();

    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  (Color, IconData, String) _resolve() {
    final a = accuracy;
    if (a == null) return (Colors.grey, Icons.lock_outline_rounded, 'Chưa làm');
    if (a < 0.4) return (Colors.redAccent, Icons.close_rounded, 'Chưa thuộc');
    if (a < 0.8) return (Colors.amber, Icons.sync_rounded, 'Đang học');
    return (Colors.green, Icons.check_rounded, 'Đã thuộc');
  }
}
