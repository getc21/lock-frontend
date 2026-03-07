import 'package:flutter/material.dart';

/// Reusable pagination control bar, driven by server-side pagination metadata.
class PaginationBar extends StatelessWidget {
  /// Current 1-based page number.
  final int currentPage;

  /// Total number of pages from server.
  final int totalPages;

  /// Total number of records from server.
  final int totalItems;

  /// Currently visible items count.
  final int visibleItems;

  /// Label for the entity type (e.g., "productos", "órdenes").
  final String itemLabel;

  /// Called with the new page number (1-based).
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.visibleItems,
    required this.itemLabel,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 0) return const SizedBox.shrink();

    return Semantics(
      label: 'Paginación: página $currentPage de $totalPages, $totalItems $itemLabel en total',
      explicitChildNodes: true,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalItems $itemLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
                tooltip: 'Primera página',
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                tooltip: 'Anterior',
                iconSize: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Página $currentPage de $totalPages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                tooltip: 'Siguiente',
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(totalPages)
                    : null,
                tooltip: 'Última página',
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    ), // close Semantics
    );
  }
}
