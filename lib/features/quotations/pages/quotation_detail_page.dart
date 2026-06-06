import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_detail_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_list_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';
import 'package:intl/intl.dart';
import 'package:bellezapp_web/core/constants/app_colors.dart';
import 'package:bellezapp_web/core/constants/app_sizes.dart';

class QuotationDetailPage extends ConsumerWidget {
  final String quotationId;

  const QuotationDetailPage({
    super.key,
    required this.quotationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationDetailState = ref.watch(quotationDetailProvider(quotationId));

    return DashboardLayout(
      title: 'Detalles de Cotización',
      currentRoute: '/quotations/$quotationId',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalles de Cotización',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    tooltip: 'Convertir a pedido',
                    onPressed: () => _showConvertDialog(context, ref, quotationId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref
                          .read(quotationDetailProvider(quotationId).notifier)
                          .refreshQuotation();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Content
          if (quotationDetailState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (quotationDetailState.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${quotationDetailState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(quotationDetailProvider(quotationId).notifier)
                          .refreshQuotation();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (quotationDetailState.quotation != null)
            Flexible(
              child: _buildContent(
                context,
                quotationDetailState.quotation!,
              ),
            )
          else
            const Center(
              child: Text('No se encontró la cotización'),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Quotation quotation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cotización #${(quotation.id ?? 'N/A').substring(0, quotation.id != null ? 8 : 3).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _buildStatusBadge(context, quotation.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  'Cliente:',
                  quotation.customerName ?? 'No especificado',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Fecha de emisión:',
                  DateFormat('dd/MM/yyyy').format(quotation.quotationDate),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Fecha de vencimiento:',
                  quotation.expirationDate != null
                      ? DateFormat('dd/MM/yyyy').format(quotation.expirationDate!)
                      : 'No definida',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Items
        Text(
          'Artículos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Cantidad'), numeric: true),
                    DataColumn(label: Text('Precio'), numeric: true),
                    DataColumn(label: Text('Total'), numeric: true),
                  ],
                  rows: quotation.items.map((item) {
                    final subtotal = item.quantity * item.price;
                    return DataRow(
                      cells: [
                        DataCell(Text(item.productName ?? 'Producto sin nombre')),
                        DataCell(Text(item.quantity.toString())),
                        DataCell(Text('Bs. ${item.price.toStringAsFixed(2)}')),
                        DataCell(Text('Bs. ${subtotal.toStringAsFixed(2)}')),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Totals
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTotalRow(
                        context,
                        'Subtotal:',
                        _calculateSubtotal(quotation),
                      ),
                      const SizedBox(height: 8),
                      if (quotation.discountAmount > 0)
                        Column(
                          children: [
                            _buildTotalRow(
                              context,
                              'Descuento:',
                              quotation.discountAmount,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      Divider(
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      _buildTotalRow(
                        context,
                        'Total:',
                        quotation.totalQuotation,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'converted':
        color = Colors.green;
        label = 'Convertido';
        break;
      case 'expired':
        color = Colors.red;
        label = 'Expirado';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelado';
        break;
      default:
        color = Colors.blue;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double amount, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : null,
          ),
        ),
        Text(
          'Bs. ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateSubtotal(Quotation quotation) {
    return quotation.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.price),
    );
  }

  void _showConvertDialog(BuildContext context, WidgetRef ref, String quotationId) {
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
                  color: Theme.of(context).primaryColor,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.transform_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    const Expanded(
                      child: Text(
                        'Convertir a pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      '¿Desea convertir esta cotización a un pedido?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacing12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Se creará un nuevo pedido con los datos de esta cotización',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
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
                      onPressed: () async {
                        final success = await ref
                            .read(quotationDetailProvider(quotationId).notifier)
                            .convertToOrder();
                        if (success) {
                          final storeState = ref.read(storeProvider);
                          final storeId = storeState.currentStore?['_id'] ?? storeState.currentStore?['id'];
                          ref.read(quotationListProvider(storeId).notifier).removeFromList(quotationId);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '¡Cotización convertida a venta exitosamente!'
                                  : 'No se pudo convertir la cotización'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          context.go('/quotations');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Convertir'),
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
