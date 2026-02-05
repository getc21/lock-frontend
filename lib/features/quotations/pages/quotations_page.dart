import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_list_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/quotation_filter_widget.dart';
import 'package:bellezapp_web/shared/widgets/quotation_card_widget.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';
import '../dialogs/quotation_detail_dialog.dart';

class QuotationsPage extends ConsumerStatefulWidget {
  const QuotationsPage({super.key});

  @override
  ConsumerState<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends ConsumerState<QuotationsPage> {
  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeId =
        storeState.currentStore?['_id'] ?? storeState.currentStore?['id'];
    final quotationListState = ref.watch(quotationListProvider(storeId));

    return DashboardLayout(
      title: 'Cotizaciones',
      currentRoute: '/quotations',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cotizaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref
                          .read(quotationListProvider(storeId).notifier)
                          .refreshQuotations();
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/orders/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Cotización'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Content
          if (quotationListState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (quotationListState.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${quotationListState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(quotationListProvider(storeId).notifier)
                          .refreshQuotations();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Filters
                QuotationFilterWidget(
                  selectedStatus: quotationListState.statusFilter,
                  startDate: quotationListState.startDate,
                  endDate: quotationListState.endDate,
                  onStatusChanged: (status) {
                    ref
                        .read(quotationListProvider(storeId).notifier)
                        .setStatusFilter(status);
                  },
                  onDateRangeChanged: (start, end) {
                    ref
                        .read(quotationListProvider(storeId).notifier)
                        .setDateRange(start, end);
                  },
                ),
                const SizedBox(height: 24),
                // Quotations list
                if (quotationListState.quotations.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.file_copy_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay cotizaciones',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea una nueva cotización para empezar',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quotationListState.quotations.length,
                    itemBuilder: (context, index) {
                      final quotation = quotationListState.quotations[index];
                      final quotationId = quotation.id ?? 'unknown';
                      return QuotationCardWidget(
                        quotation: quotation,
                        onTap: () => showQuotationDetailDialog(
                          context,
                          ref,
                          quotationId,
                          storeId: storeId,
                        ),
                        onDelete: () => _showDeleteDialog(
                          context,
                          ref,
                          quotationId,
                          storeId,
                        ),
                      );
                    },
                  ),
                // Pagination info
                if (quotationListState.quotations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Página ${quotationListState.currentPage} de ${(quotationListState.totalItems / quotationListState.pageSize).ceil()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String quotationId,
    String? storeId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta cotización?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(quotationListProvider(storeId).notifier)
                  .deleteQuotation(quotationId);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
