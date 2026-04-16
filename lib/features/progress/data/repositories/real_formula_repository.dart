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
    final json = await _client.get('/formulas', queryParams: {'search': query});
    // The search response may have formulas nested in categories
    final categories = _parseCategories(json);
    final results = <Formula>[];
    for (final cat in categories) {
      results.addAll(cat.formulas);
    }
    return results;
  }

  List<FormulaCategory> _parseCategories(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    if (rawCategories is! List) return const [];

    return rawCategories
        .whereType<Map<String, dynamic>>()
        .map((cat) {
          final rawFormulas = cat['formulas'];
          final formulas = <Formula>[];
          if (rawFormulas is List) {
            for (final f in rawFormulas) {
              if (f is Map<String, dynamic>) {
                formulas.add(_mapFormula(f, cat['id']?.toString()));
              }
            }
          }
          return FormulaCategory(
            id: (cat['id'] ?? '').toString(),
            name: (cat['name'] ?? '').toString(),
            icon: _iconForCategory((cat['id'] ?? '').toString()),
            formulas: formulas,
          );
        })
        .toList(growable: false);
  }

  /// Map backend formula shape to frontend Formula model.
  Formula _mapFormula(Map<String, dynamic> f, String? categoryId) {
    return Formula(
      id: (f['id'] ?? '').toString(),
      latex: (f['formula_text'] ?? f['latex'] ?? '').toString(),
      explanation: (f['description'] ?? f['explanation'] ?? '').toString(),
      exampleLatex: f['example_latex']?.toString(),
      exampleExplanation: f['example_explanation']?.toString(),
      hypothesis: f['hypothesis']?.toString(),
      difficulty: (f['difficulty'] ?? 'easy').toString(),
      categoryId: categoryId,
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
