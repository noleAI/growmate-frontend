import '../models/formula.dart';
import '../models/formula_category.dart';

/// Abstract interface cho formula data.
abstract class FormulaRepository {
  Future<List<FormulaCategory>> getAllCategories();
  Future<List<Formula>> searchFormulas(String query);
}
