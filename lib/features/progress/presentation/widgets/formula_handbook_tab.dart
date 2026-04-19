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
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.62),
                  theme.colorScheme.tertiaryContainer.withValues(alpha: 0.48),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(
                          vi: 'Sổ tay công thức Toán',
                          en: 'Math Formula Handbook',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t(
                          vi: 'Nội dung tham chiếu nhanh, cập nhật dần theo chương.',
                          en: 'Quick reference content, expanded gradually by chapters.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: FormulaSearchBar(
            onChanged: context.read<FormulaCubit>().search,
            onClear: context.read<FormulaCubit>().clearSearch,
          ),
        ),
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
    final theme = Theme.of(context);

    if (isSearching) {
      final results = searchResults;
      if (results == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (results.isEmpty) {
        return const _EmptySearch();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: results.length,
          itemBuilder: (_, i) => FormulaDetailCard(formula: results[i]),
        ),
      );
    }

    if (categories.isEmpty) {
      return const _EmptyHandbook();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24, top: 10),
        itemCount: categories.length,
        itemBuilder: (_, i) => FormulaCategoryCard(category: categories[i]),
      ),
    );
  }
}

class _EmptyHandbook extends StatelessWidget {
  const _EmptyHandbook();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                context.t(
                  vi: 'Chưa có dữ liệu sổ tay công thức.',
                  en: 'No handbook data available yet.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t(
                  vi: 'Nội dung tham chiếu sẽ hiển thị khi bộ công thức được nạp thành công.',
                  en: 'Reference content will appear once the formula set is loaded.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.t(
                vi: 'Không tìm thấy công thức',
                en: 'No formulas found',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                vi: 'Thử từ khóa ngắn hơn hoặc tìm theo chương/chủ đề.',
                en: 'Try a shorter keyword or search by chapter/topic.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
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
