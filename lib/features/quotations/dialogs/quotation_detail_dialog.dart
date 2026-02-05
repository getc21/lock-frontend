import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_detail_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_list_notifier.dart';
import 'package:intl/intl.dart';

void showQuotationDetailDialog(
  BuildContext context,
  WidgetRef ref,
  String quotationId,
  {String? storeId}
) {
  showDialog(
    context: context,
    builder: (context) => QuotationDetailDialog(
      quotationId: quotationId,
      storeId: storeId,
    ),
  );
}

class QuotationDetailDialog extends ConsumerWidget {
  final String quotationId;
  final String? storeId;

  const QuotationDetailDialog({
    super.key,
    required this.quotationId,
    this.storeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationDetailState = ref.watch(quotationDetailProvider(quotationId));

    return Dialog(
      child: Container(
        width: 900,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalles de Cotización',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: quotationDetailState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : quotationDetailState.error != null
                      ? Center(
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
                      : quotationDetailState.quotation != null
                          ? _buildContent(context, ref, quotationDetailState.quotation!)
                          : const Center(
                              child: Text('No se encontró la cotización'),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Quotation quotation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 24),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              const SizedBox(width: 8),
              if (quotation.status == 'pending')
                ElevatedButton.icon(
                  onPressed: () => _showConvertDialog(context, ref, quotation.id ?? 'unknown'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Convertir a pedido'),
                ),
            ],
          ),
        ],
      ),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Convertir a pedido'),
        content: const Text(
          '¿Desea convertir esta cotización a un pedido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Cerrar ambos diálogos primero (antes de async operations)
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              
              await ref
                  .read(quotationDetailProvider(quotationId).notifier)
                  .convertToOrder();
              
              // Recargar la lista de cotizaciones si tenemos storeId
              if (storeId != null) {
                await ref
                    .read(quotationListProvider(storeId).notifier)
                    .refreshQuotations();
              }
            },
            child: const Text('Convertir'),
          ),
        ],
      ),
    );
  }
}
