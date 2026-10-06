import 'package:flutter/material.dart';
import 'theme.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: CivilTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CivilTheme.textSecondary),
        prefixIcon: const Icon(Icons.search, color: CivilTheme.textSecondary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: CivilTheme.textSecondary),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: CivilTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CivilTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CivilTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CivilTheme.primary, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ValueChanged<int> onPageChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            color: currentPage > 1 ? CivilTheme.primary : CivilTheme.textSecondary,
          ),
          ...List.generate(totalPages.clamp(1, 5), (i) {
            final pageNum = i + 1;
            final isSelected = pageNum == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('$pageNum'),
                selected: isSelected,
                onSelected: (v) {
                  if (v) onPageChanged(pageNum);
                },
                selectedColor: CivilTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : CivilTheme.textSecondary,
                ),
              ),
            );
          }),
          if (totalPages > 5) ...[
            Text('...', style: TextStyle(color: CivilTheme.textSecondary)),
            ChoiceChip(
              label: Text('$totalPages'),
              selected: currentPage == totalPages,
              onSelected: (v) {
                if (v) onPageChanged(totalPages);
              },
              selectedColor: CivilTheme.primary,
              labelStyle: TextStyle(
                color: currentPage == totalPages ? Colors.white : CivilTheme.textSecondary,
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasMore ? () => onPageChanged(currentPage + 1) : null,
            color: hasMore ? CivilTheme.primary : CivilTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}
