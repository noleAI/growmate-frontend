import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/formula.dart';
import '../../data/repositories/formula_repository.dart';
import '../cubit/formula_cubit.dart';
import '../cubit/formula_state.dart';
import 'formula_category_card.dart';
import 'formula_detail_card.dart';
import 'formula_search_bar.dart';

/// Tab "Sổ tay công thức" trong Progress page.
///
/// Cung cấp `BlocProvider<FormulaCubit>` nội bộ để không phụ thuộc
/// vào parent widget tree.
class FormulaHandbookTab extends StatelessWidget {
  const FormulaHandbookTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          FormulaCubit(repository: ctx.read<FormulaRepository>())..loadAll(),
      child: const _FormulaHandbookBody(),
    );
  }
}

class _FormulaHandbookBody extends StatelessWidget {
  const _FormulaHandbookBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: FormulaSearchBar(
            onChanged: context.read<FormulaCubit>().search,
            onClear: context.read<FormulaCubit>().clearSearch,
          ),
        ),
        // Content
        Expanded(
          child: BlocBuilder<FormulaCubit, FormulaState>(
            builder: (context, state) {
              return switch (state) {
                FormulaInitial() || FormulaLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                FormulaError(:final message) => _ErrorView(message: message),
                FormulaLoaded(
                  :final categories,
                  :final searchResults,
                  :final isSearching,
                ) =>
                  _ContentView(
                    categories: categories,
                    searchResults: searchResults,
                    isSearching: isSearching,
                  ),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({
    required this.categories,
    required this.searchResults,
    required this.isSearching,
  });

  final List categories;
  final List<Formula>? searchResults;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      final results = searchResults;
      if (results == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (results.isEmpty) {
        return const _EmptySearch();
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: results.length,
        itemBuilder: (_, i) => FormulaDetailCard(formula: results[i]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length,
      itemBuilder: (_, i) =>
          FormulaCategoryCard(category: categories[i] as dynamic),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy công thức',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Lỗi: $message', style: const TextStyle(color: Colors.red)),
    );
  }
}
