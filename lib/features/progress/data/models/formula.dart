/// Một công thức toán học trong sổ tay.
class Formula {
  const Formula({
    required this.id,
    required this.latex,
    required this.explanation,
    this.exampleLatex,
    this.exampleExplanation,
    this.hypothesis,
    required this.difficulty,
    this.categoryId,
  });

  final String id;

  /// LaTeX biểu diễn công thức chính
  final String latex;

  final String explanation;

  /// LaTeX ví dụ áp dụng
  final String? exampleLatex;

  final String? exampleExplanation;

  /// Hypothesis tag liên quan (H01, H02, H03, H04)
  final String? hypothesis;

  /// 'easy' | 'medium' | 'hard'
  final String difficulty;

  /// ID của category cha
  final String? categoryId;

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'] as String,
      latex: json['latex'] as String,
      explanation: json['explanation'] as String,
      exampleLatex: json['example_latex'] as String?,
      exampleExplanation: json['example_explanation'] as String?,
      hypothesis: json['hypothesis'] as String?,
      difficulty: json['difficulty'] as String? ?? 'easy',
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'latex': latex,
    'explanation': explanation,
    'example_latex': exampleLatex,
    'example_explanation': exampleExplanation,
    'hypothesis': hypothesis,
    'difficulty': difficulty,
    'category_id': categoryId,
  };
}
