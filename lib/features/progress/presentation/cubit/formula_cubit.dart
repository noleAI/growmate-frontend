import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/formula_repository.dart';
import 'formula_state.dart';

class FormulaCubit extends Cubit<FormulaState> {
  FormulaCubit({required FormulaRepository repository})
    : _repository = repository,
      super(const FormulaInitial());

  final FormulaRepository _repository;

  Future<void> loadAll() async {
    emit(const FormulaLoading());
    try {
      final categories = await _repository.getAllCategories();
      emit(FormulaLoaded(categories: categories));
    } catch (e) {
      emit(FormulaError(e.toString()));
    }
  }

  Future<void> search(String query) async {
    final current = state;
    if (current is! FormulaLoaded) return;

    if (query.trim().isEmpty) {
      emit(current.copyWith(searchQuery: '', searchResults: null));
      return;
    }

    emit(current.copyWith(searchQuery: query));
    final results = await _repository.searchFormulas(query);
    // Re-read state in case it changed
    final after = state;
    if (after is FormulaLoaded && after.searchQuery == query) {
      emit(after.copyWith(searchResults: results));
    }
  }

  void clearSearch() {
    final current = state;
    if (current is FormulaLoaded) {
      emit(current.copyWith(searchQuery: '', searchResults: null));
    }
  }
}
