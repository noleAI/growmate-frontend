import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';

/// Thanh tìm kiếm cho sổ tay công thức.
class FormulaSearchBar extends StatefulWidget {
  const FormulaSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<FormulaSearchBar> createState() => _FormulaSearchBarState();
}

class _FormulaSearchBarState extends State<FormulaSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: context.t(vi: 'Tìm công thức...', en: 'Search formulas...'),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
    );
  }
}
