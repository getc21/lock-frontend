import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/order_detail_notifier.dart';
import '../../shared/providers/riverpod/order_detail_selectors.dart';

/// Página de detalle de una orden específica
/// Utiliza orderDetailProvider (.family) para lazy loading
class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    // Cargar detalle cuando entra a la página
    Future.microtask(() {
      ref.read(orderDetailProvider(widget.orderId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para observar solo lo que cambió
    final isLoading = ref.watch(orderLoadingSelector(widget.orderId));
    final error = ref.watch(orderErrorSelector(widget.orderId));
    final order = ref.watch(orderSelector(widget.orderId));

    return DashboardLayout(
      title: 'Detalle de Orden',
      currentRoute: '/orders',
      child: isLoading
          ? const Center(child: LoadingIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(orderDetailProvider(widget.orderId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : order != null
                  ? _OrderDetailContent(
                      order: order,
                      onStatusChange: (newStatus) async {
                        final success = await ref
                            .read(
                                orderDetailProvider(widget.orderId).notifier)
                            .updateOrderStatus(status: newStatus);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Estado actualizado correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al actualizar estado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    )
                  : const Center(
                      child: Text('No se encontró la orden'),
                    ),
    );
  }
}

/// Widget de contenido de detalle de orden
class _OrderDetailContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;

  const _OrderDetailContent({
    required this.order,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    const currency = '\$';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con ID y estado
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${order['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(status: order['status'] ?? 'unknown'),
                      PopupMenuButton<String>(
                        onSelected: onStatusChange,
                        itemBuilder: (BuildContext context) => [
                          'pending',
                          'confirmed',
                          'completed',
                          'cancelled',
                        ]
                            .map((status) => PopupMenuItem(
                                  value: status,
                                  child: Text(_formatStatus(status)),
                                ))
                            .toList(),
                        child: const Text('Cambiar estado'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Información general
          _SectionTitle(title: 'Información General'),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Cliente:',
            value: order['customerId'] ?? 'N/A',
          ),
          _InfoRow(
            label: 'Tienda:',
            value: order['storeId'] ?? 'N/A',
          ),
          _InfoRow(
            label: 'Método de Pago:',
            value: _formatPaymentMethod(order['paymentMethod'] ?? 'N/A'),
          ),
          _InfoRow(
            label: 'Fecha:',
            value: _formatDate(order['createdAt']),
          ),
          const SizedBox(height: 24),

          // Totales
          _SectionTitle(title: 'Resumen'),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TotalRow(
                    label: 'Subtotal:',
                    value:
                        '$currency${(order['subtotal'] ?? 0).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  if (order['discount'] != null && order['discount'] > 0)
                    Column(
                      children: [
                        _TotalRow(
                          label: 'Descuento:',
                          value:
                              '-$currency${(order['discount'] ?? 0).toStringAsFixed(2)}',
                          valueColor: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  const Divider(thickness: 1),
                  _TotalRow(
                    label: 'Total:',
                    value: '$currency${(order['total'] ?? 0).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Items de la orden
          if (order['items'] != null && (order['items'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Items'),
                const SizedBox(height: 12),
                ...(order['items'] as List)
                    .asMap()
                    .entries
                    .map((entry) => _OrderItem(item: entry.value, currency: currency))
                    .toList(),
              ],
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    const Map<String, String> methods = {
      'cash': 'Efectivo',
      'card': 'Tarjeta',
      'transfer': 'Transferencia',
    };
    return methods[method] ?? method;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatStatus(String status) {
    const Map<String, String> statuses = {
      'pending': 'Pendiente',
      'confirmed': 'Confirmada',
      'completed': 'Completada',
      'cancelled': 'Cancelada',
    };
    return statuses[status] ?? status;
  }
}

/// Widget para mostrar una fila de información
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar un total
class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

/// Widget de badge de estado
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        displayText = 'Pendiente';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        displayText = 'Confirmada';
        break;
      case 'completed':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        displayText = 'Completada';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        displayText = 'Cancelada';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Widget para título de sección
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Widget para mostrar un item de la orden
class _OrderItem extends StatelessWidget {
  final dynamic item;
  final String currency;

  const _OrderItem({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? 'Producto desconocido',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad: ${item['quantity'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currency${((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
