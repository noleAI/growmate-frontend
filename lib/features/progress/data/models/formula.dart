/// Một công thức toán học trong sổ tay.
class Formula {
  const Formula({
    required this.id,
    this.title,
    required this.latex,
    required this.explanation,
    this.example,
    this.exampleLatex,
    this.exampleExplanation,
    this.hypothesis,
    required this.difficulty,
    this.categoryId,
    this.masteryPercent,
    this.masteryStatus,
  });

  final String id;
  final String? title;

  /// LaTeX biểu diễn công thức chính
  final String latex;

  final String explanation;

  /// Example text when backend doesn't provide a dedicated LaTeX example.
  final String? example;

  /// LaTeX ví dụ áp dụng
  final String? exampleLatex;

  final String? exampleExplanation;

  /// Hypothesis tag liên quan (H01, H02, H03, H04)
  final String? hypothesis;

  /// 'easy' | 'medium' | 'hard'
  final String difficulty;

  /// ID của category cha
  final String? categoryId;

  /// Backend mastery in percentage form (0-100).
  final double? masteryPercent;

  /// Backend mastery label, e.g. `new`, `learning`, `mastered`.
  final String? masteryStatus;

  double? get masteryAccuracy {
    final percent = masteryPercent;
    if (percent == null) {
      return null;
    }
    return (percent / 100).clamp(0.0, 1.0);
  }

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString(),
      latex: (json['latex'] ?? json['formula_text'] ?? '').toString(),
      explanation: (json['explanation'] ?? json['description'] ?? '')
          .toString(),
      example: json['example']?.toString(),
      exampleLatex: json['example_latex']?.toString(),
      exampleExplanation: json['example_explanation']?.toString(),
      hypothesis: json['hypothesis']?.toString(),
      difficulty: (json['difficulty'] ?? 'easy').toString(),
      categoryId: json['category_id']?.toString(),
      masteryPercent: _toDouble(json['mastery_percent']),
      masteryStatus: json['mastery_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'latex': latex,
    'explanation': explanation,
    'example': example,
    'example_latex': exampleLatex,
    'example_explanation': exampleExplanation,
    'hypothesis': hypothesis,
    'difficulty': difficulty,
    'category_id': categoryId,
    'mastery_percent': masteryPercent,
    'mastery_status': masteryStatus,
  };
}

double? _toDouble(Object? raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
