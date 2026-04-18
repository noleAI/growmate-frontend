import 'formula.dart';

/// Nhóm công thức (category) trong sổ tay.
class FormulaCategory {
  const FormulaCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.formulas,
    this.description,
    this.formulaCountOverride,
    this.masteryPercent,
  });

  final String id;
  final String name;
  final String icon;
  final List<Formula> formulas;
  final String? description;
  final int? formulaCountOverride;
  final double? masteryPercent;

  int get formulaCount => formulaCountOverride ?? formulas.length;

  double? get masteryAccuracy {
    final percent = masteryPercent;
    if (percent == null) {
      return null;
    }
    return (percent / 100).clamp(0.0, 1.0);
  }

  factory FormulaCategory.fromJson(Map<String, dynamic> json) {
    return FormulaCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      description: json['description']?.toString(),
      formulaCountOverride: _toInt(json['formula_count']),
      masteryPercent: _toDouble(json['mastery_percent']),
      formulas:
          (json['formulas'] as List<dynamic>?)
              ?.map((e) => Formula.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const <Formula>[],
    );
  }
}

int? _toInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

double? _toDouble(Object? raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
