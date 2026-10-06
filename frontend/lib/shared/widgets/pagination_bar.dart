import 'package:flutter/material.dart';
import '../../core/models/pagination.dart';
import '../../core/theme.dart';

class PaginationBar extends StatelessWidget {
  final PaginationMeta meta;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool isLoading;

  const PaginationBar({
    super.key,
    required this.meta,
    this.onPrev,
    this.onNext,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (meta.totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: meta.hasPrev ? onPrev : null,
              color: meta.hasPrev ? CivilTheme.primary : CivilTheme.textSecondary,
            ),
            Text(
              'Page ${meta.page} of ${meta.totalPages} (${meta.total} items)',
              style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: meta.hasNext ? onNext : null,
              color: meta.hasNext ? CivilTheme.primary : CivilTheme.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
