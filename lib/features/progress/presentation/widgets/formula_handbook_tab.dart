import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../data/models/formula.dart';
import '../../data/models/formula_category.dart';
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
                FormulaError(:final message) => _ErrorView(
                  message: message,
                  onRetry: context.read<FormulaCubit>().loadAll,
                ),
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

  final List<FormulaCategory> categories;
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

    if (categories.isEmpty) {
      return const _EmptyHandbook();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length,
      itemBuilder: (_, i) => FormulaCategoryCard(category: categories[i]),
    );
  }
}

class _EmptyHandbook extends StatelessWidget {
  const _EmptyHandbook();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              context.t(
                vi: 'Chưa có dữ liệu sổ tay công thức.',
                en: 'No handbook data available yet.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
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
            context.t(vi: 'Không tìm thấy công thức', en: 'No formulas found'),
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
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              context.t(
                vi: 'Không tải được sổ tay công thức.',
                en: 'Unable to load formula handbook.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t(vi: 'Thử lại', en: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}
