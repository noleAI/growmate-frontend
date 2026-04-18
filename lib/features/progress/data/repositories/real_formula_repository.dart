import '../../../../core/network/rest_api_client.dart';
import '../models/formula.dart';
import '../models/formula_category.dart';
import 'formula_repository.dart';

/// Real implementation calling the backend REST API.
class RealFormulaRepository implements FormulaRepository {
  RealFormulaRepository({required RestApiClient client}) : _client = client;

  final RestApiClient _client;

  @override
  Future<List<FormulaCategory>> getAllCategories() async {
    final json = await _client.get(
      '/formulas',
      queryParams: {'category': 'all'},
    );
    return _parseCategories(json);
  }

  @override
  Future<List<Formula>> searchFormulas(String query) async {
    if (query.trim().isEmpty) return const <Formula>[];
    final json = await _client.get(
      '/formulas',
      queryParams: {'category': 'all', 'search': query},
    );
    final directResults = _parseFormulas(json['formulas']);
    if (directResults.isNotEmpty) {
      return directResults;
    }

    // The search response may also return formulas nested inside categories.
    final categories = _parseCategories(json);
    final results = <Formula>[];
    for (final cat in categories) {
      results.addAll(cat.formulas);
    }
    return results;
  }

  List<FormulaCategory> _parseCategories(Map<String, dynamic> json) {
    final rawCategories = json['categories'] ?? json['items'];
    if (rawCategories is! List) return const [];

    return rawCategories
        .whereType<Map<String, dynamic>>()
        .map((cat) {
          final formulas = _parseFormulas(
            cat['formulas'],
            categoryId: cat['id']?.toString(),
          );
          return FormulaCategory(
            id: (cat['id'] ?? '').toString(),
            name: (cat['name'] ?? '').toString(),
            icon: _iconForCategory((cat['id'] ?? '').toString()),
            description: cat['description']?.toString(),
            formulaCountOverride: _toInt(cat['formula_count']),
            masteryPercent: _toDouble(cat['mastery_percent']),
            formulas: formulas,
          );
        })
        .toList(growable: false);
  }

  List<Formula> _parseFormulas(Object? raw, {String? categoryId}) {
    if (raw is! List) {
      return const <Formula>[];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((f) => _mapFormula(f, categoryId))
        .toList(growable: false);
  }

  /// Map backend formula shape to frontend Formula model.
  Formula _mapFormula(Map<String, dynamic> f, String? categoryId) {
    return Formula(
      id: (f['id'] ?? '').toString(),
      title: f['title']?.toString(),
      latex: (f['formula_text'] ?? f['latex'] ?? '').toString(),
      explanation: (f['description'] ?? f['explanation'] ?? '').toString(),
      example: f['example']?.toString(),
      exampleLatex: f['example_latex']?.toString(),
      exampleExplanation: f['example_explanation']?.toString(),
      hypothesis: f['hypothesis']?.toString(),
      difficulty: (f['difficulty'] ?? 'easy').toString(),
      categoryId: categoryId,
      masteryPercent: _toDouble(f['mastery_percent']),
      masteryStatus: f['mastery_status']?.toString(),
    );
  }

  /// Map category id to a display icon. Backend doesn't return icons.
  String _iconForCategory(String categoryId) {
    return switch (categoryId) {
      'basic_derivatives' => '📊',
      'arithmetic_rules' => '🔢',
      'basic_trig' => '📐',
      'exp_log' => '📈',
      'chain_rule' => '🔗',
      _ => '📖',
    };
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
