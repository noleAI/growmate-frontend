import '../../data/models/formula.dart';
import '../../data/models/formula_category.dart';

sealed class FormulaState {
  const FormulaState();
}

final class FormulaInitial extends FormulaState {
  const FormulaInitial();
}

final class FormulaLoading extends FormulaState {
  const FormulaLoading();
}

final class FormulaLoaded extends FormulaState {
  static const Object _unset = Object();

  const FormulaLoaded({
    required this.categories,
    this.searchResults,
    this.searchQuery = '',
  });

  final List<FormulaCategory> categories;
  final List<Formula>? searchResults;
  final String searchQuery;

  bool get isSearching => searchQuery.isNotEmpty;

  FormulaLoaded copyWith({
    List<FormulaCategory>? categories,
    Object? searchResults = _unset,
    String? searchQuery,
  }) {
    return FormulaLoaded(
      categories: categories ?? this.categories,
      searchResults: identical(searchResults, _unset)
          ? this.searchResults
          : searchResults as List<Formula>?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final class FormulaError extends FormulaState {
  const FormulaError(this.message);
  final String message;
}
