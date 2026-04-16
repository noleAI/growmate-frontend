import 'formula.dart';

/// Nhóm công thức (category) trong sổ tay.
class FormulaCategory {
  const FormulaCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.formulas,
  });

  final String id;
  final String name;
  final String icon;
  final List<Formula> formulas;

  int get formulaCount => formulas.length;

  factory FormulaCategory.fromJson(Map<String, dynamic> json) {
    return FormulaCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      formulas:
          (json['formulas'] as List<dynamic>?)
              ?.map((e) => Formula.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const <Formula>[],
    );
  }
}
