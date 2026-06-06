import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_list_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/features/quotations/services/quotation_pdf_service.dart';
import 'package:bellezapp_web/core/constants/app_colors.dart';
import 'package:bellezapp_web/core/constants/app_sizes.dart';
import '../dialogs/quotation_detail_dialog.dart';

class QuotationsPage extends ConsumerStatefulWidget {
  const QuotationsPage({super.key});

  @override
  ConsumerState<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends ConsumerState<QuotationsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeState = ref.read(storeProvider);
      final storeId =
          storeState.currentStore?['_id'] ?? storeState.currentStore?['id'];
      final currentState = ref.read(quotationListProvider(storeId));
      // Solo recargar si no hay datos aún (primera carga).
      // Si ya hay datos (p.ej. recién se creó una cotización), no sobreescribir.
      if (currentState.quotations.isEmpty && !currentState.isLoading) {
        ref.read(quotationListProvider(storeId).notifier).refreshQuotations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por cliente...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: () => ref
                    .read(quotationListProvider(storeId).notifier)
                    .refreshQuotations(),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => context.go('/orders/create'),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Cotización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table
          Expanded(
            child: () {
              if (quotationListState.isLoading) {
                return const Card(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (quotationListState.error != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: ${quotationListState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(quotationListProvider(storeId).notifier)
                            .refreshQuotations(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final filtered = quotationListState.quotations.where((q) {
                return _searchQuery.isEmpty ||
                    (q.customerName ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return Card(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_copy_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No hay cotizaciones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('Crea una nueva cotización para empezar',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 16,
                  minWidth: 900,
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ),
                  columns: const [
                    DataColumn2(label: Text('# Ref'), size: ColumnSize.S),
                    DataColumn2(label: Text('Cliente'), size: ColumnSize.L),
                    DataColumn2(label: Text('Items'), size: ColumnSize.S),
                    DataColumn2(label: Text('Total'), size: ColumnSize.S),
                    DataColumn2(label: Text('Vencimiento'), size: ColumnSize.S),
                    DataColumn2(label: Text('Fecha'), size: ColumnSize.S),
                    DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                  ],
                  rows: filtered.map((q) => _buildRow(context, q, storeId)).toList(),
                ),
              );
            }(),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(BuildContext context, Quotation q, String? storeId) {
    final dateFormat = DateFormat('dd/MM/yy');
    final shortId = (q.id ?? 'N/A')
        .substring(0, q.id != null ? 8 : 3)
        .toUpperCase();
    final quotationId = q.id ?? 'unknown';

    return DataRow2(
      cells: [
        DataCell(Text('#$shortId',
            style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'monospace'))),
        DataCell(Text(q.customerName ?? '-')),
        DataCell(Text('${q.items.length}')),
        DataCell(Text(
          'Bs. ${q.totalQuotation.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        DataCell(Text(
          q.expirationDate != null ? dateFormat.format(q.expirationDate!) : '-',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        )),
        DataCell(Text(
          dateFormat.format(q.quotationDate),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        )),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              color: Colors.blueGrey,
              tooltip: 'Exportar PDF',
              onPressed: () => QuotationPdfService.exportToPdf(q),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              tooltip: 'Eliminar',
              onPressed: () => _showDeleteDialog(context, ref, quotationId, storeId),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: 'Ver detalle',
              onPressed: () => showQuotationDetailDialog(
                context,
                ref,
                quotationId,
                storeId: storeId,
              ),
            ),
          ],
        )),
      ],
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    const Expanded(
                      child: Text(
                        'Eliminar cotización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // CONTENT
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿Está seguro de que desea eliminar esta cotización?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Esta acción no se puede deshacer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // FOOTER
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(quotationListProvider(storeId).notifier)
                            .deleteQuotation(quotationId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


