import '../mock/mock_formula_data.dart';
import '../models/formula.dart';
import '../models/formula_category.dart';
import 'formula_repository.dart';

/// Mock implementation — load từ hardcoded data.
class MockFormulaRepository implements FormulaRepository {
  @override
  Future<List<FormulaCategory>> getAllCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockFormulaCategories;
  }

  @override
  Future<List<Formula>> searchFormulas(String query) async {
    if (query.trim().isEmpty) return const <Formula>[];
    final lower = query.toLowerCase();
    final results = <Formula>[];
    for (final cat in mockFormulaCategories) {
      for (final formula in cat.formulas) {
        if (formula.explanation.toLowerCase().contains(lower) ||
            formula.latex.toLowerCase().contains(lower) ||
            (formula.exampleExplanation?.toLowerCase().contains(lower) ??
                false)) {
          results.add(formula);
        }
      }
    }
    return results;
  }
}
