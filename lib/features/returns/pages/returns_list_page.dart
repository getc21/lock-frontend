import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/dashboard_layout.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/providers/riverpod/store_notifier.dart';
import '../models/return_models.dart';
import '../services/returns_service.dart';

class ReturnsListPage extends ConsumerStatefulWidget {
  const ReturnsListPage({super.key});

  @override
  ConsumerState<ReturnsListPage> createState() => _ReturnsListPageState();
}

class _ReturnsListPageState extends ConsumerState<ReturnsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final currentStoreId = storeState.currentStore?['_id'] as String?;

    if (currentStoreId == null) {
      return DashboardLayout(
        title: 'Devoluciones',
        currentRoute: '/returns',
        child: const Center(child: Text('No hay tienda seleccionada')),
      );
    }

    final returnsAsync = ref.watch(
      returnsProvider(ReturnFilters(storeId: currentStoreId)),
    );

    return DashboardLayout(
      title: 'Devoluciones',
      currentRoute: '/returns',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por orden o cliente...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nueva Devolucion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                    vertical: AppSizes.spacing12,
                  ),
                ),
                onPressed: () => context.go('/orders'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          const Text(
            'Para crear una devolucion, ve a Ordenes y selecciona una orden.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: AppSizes.spacing16),
          Expanded(
            child: returnsAsync.when(
              loading: () => const Card(
                child: Center(child: LoadingIndicator()),
              ),
              error: (error, stack) {
                debugPrint('ReturnsListPage Error: $error');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text(
                        'Error al cargar devoluciones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(
                          returnsProvider(ReturnFilters(storeId: currentStoreId)),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              },
              data: (data) {
                final allReturns = data['returns'] as List<ReturnRequest>;

                final filtered = _searchQuery.isEmpty
                    ? allReturns
                    : allReturns.where((r) {
                        final q = _searchQuery.toLowerCase();
                        return r.orderNumber.toLowerCase().contains(q) ||
                            r.customerName.toLowerCase().contains(q);
                      }).toList();

                if (allReturns.isEmpty) {
                  return Card(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay devoluciones registradas',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ve a Ordenes, selecciona una orden y usa el boton "Crear Devolucion"',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: const Text('Ir a Ordenes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed: () => context.go('/orders'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final totalPages = (filtered.length / _itemsPerPage).ceil();
                final startIndex = _currentPage * _itemsPerPage;
                final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
                final pageItems = filtered.sublist(startIndex, endIndex);

                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          minWidth: 800,
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primary.withValues(alpha: 0.05),
                          ),
                          columns: const [
                            DataColumn2(label: Text('Orden'), size: ColumnSize.S),
                            DataColumn2(label: Text('Cliente'), size: ColumnSize.M),
                            DataColumn2(label: Text('Tipo'), size: ColumnSize.S),
                            DataColumn2(label: Text('Monto'), size: ColumnSize.S),
                            DataColumn2(label: Text('Metodo'), size: ColumnSize.S),
                            DataColumn2(label: Text('Fecha'), size: ColumnSize.S),
                          ],
                          rows: pageItems.map((r) => _buildRow(r)).toList(),
                        ),
                      ),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing16,
                            vertical: AppSizes.spacing8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mostrando ${startIndex + 1}-$endIndex de ${filtered.length}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                  ),
                                  Text('${_currentPage + 1} / $totalPages'),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < totalPages - 1
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(ReturnRequest r) {
    final dateStr = r.requestedAt != null
        ? DateFormat('dd/MM/yy').format(r.requestedAt!)
        : '-';

    return DataRow2(
      onSelectChanged: (_) => _showDetail(r),
      cells: [
        DataCell(Text(r.orderNumber, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(r.customerName)),
        DataCell(_TypeChip(r.type)),
        DataCell(Text(
          '\$${r.totalRefundAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        DataCell(Text(r.refundMethod.label)),
        DataCell(Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey))),
      ],
    );
  }

  void _showDetail(ReturnRequest r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devolucion #${r.orderNumber}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _StatusBadge(r.status),
                              const SizedBox(width: 8),
                              _TypeChip(r.type),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Cliente', r.customerName),
                      _InfoRow('Metodo de reembolso', r.refundMethod.label),
                      _InfoRow('Razon', r.returnReasonCategory.label),
                      if (r.returnReasonDetails != null && r.returnReasonDetails!.isNotEmpty)
                        _InfoRow('Detalle', r.returnReasonDetails!),
                      if (r.requestedAt != null)
                        _InfoRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(r.requestedAt!)),
                      const SizedBox(height: 20),
                      const Text(
                        'Productos devueltos',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('Cant.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('Precio unit.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                        ],
                      ),
                      const Divider(height: 8),
                      ...r.items.map((item) {
                        final subtotal = item.returnQuantity * item.unitPrice;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(item.productName ?? 'Producto', style: const TextStyle(fontSize: 13))),
                              Expanded(flex: 1, child: Text('x${item.returnQuantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                              Expanded(flex: 2, child: Text('\$${item.unitPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                              Expanded(flex: 2, child: Text('\$${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Total reembolso: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '\$${r.totalRefundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // FOOTER
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Cerrar'),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReturnStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;
    switch (status) {
      case ReturnStatus.pending:
        color = Colors.orange.shade700;
        bg = Colors.orange.shade50;
        break;
      case ReturnStatus.approved:
        color = Colors.blue.shade700;
        bg = Colors.blue.shade50;
        break;
      case ReturnStatus.completed:
        color = Colors.green.shade700;
        bg = Colors.green.shade50;
        break;
      case ReturnStatus.rejected:
        color = Colors.red.shade700;
        bg = Colors.red.shade50;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ReturnType type;
  const _TypeChip(this.type);

  @override
  Widget build(BuildContext context) {
    return Text(type.label, style: const TextStyle(fontSize: 12));
  }
}
