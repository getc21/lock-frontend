import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/controllers/order_controller.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderController _orderController;
  String _paymentFilter = 'Todos';
  late final ScrollController _scrollController;
  
  // Variables para optimizar rendimiento
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _orderController = Get.find<OrderController>();
    _scrollController = ScrollController();
    
    // Cargar datos de forma no bloqueante
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _loadOrdersOptimized();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOrdersOptimized() async {
    // Solo ejecutar la carga si no hay órdenes cargadas todavía
    if (_orderController.orders.isEmpty && !_orderController.isLoading) {
      await _orderController.loadOrdersForCurrentStore();
    }
    // Marcar como inicializado solo después de que se complete la carga
    // o cuando ya hay órdenes disponibles
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _hasInitialized = true;
        _updateFilteredOrders();
      }
    });
  }

  void _updateFilteredOrders() {
    // Calcular órdenes filtradas sin reconstruir todo
    _filteredOrders = _orderController.orders
        .where((o) => _paymentFilter == 'Todos' || o['paymentMethod'] == _paymentFilter)
        .toList();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Órdenes',
      currentRoute: '/orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filters
          Row(
            children: [
              DropdownButton<String>(
                value: _paymentFilter,
                items: ['Todos', 'efectivo', 'tarjeta', 'transferencia']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method == 'Todos' ? 'Todos' : method[0].toUpperCase() + method.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentFilter = value!;
                    _updateFilteredOrders();
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/orders/create'),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Orden'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Orders Table
          Obx(() {
            // Mostrar loading mientras se cargan datos O si no está inicializado aún
            if (_orderController.isLoading || !_hasInitialized) {
              return SizedBox(
                height: 600,
                child: Card(
                  child: Center(
                    child: LoadingIndicator(
                      message: 'Cargando órdenes...',
                    ),
                  ),
                ),
              );
            }

            if (_orderController.orders.isEmpty) {
              return Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay órdenes disponibles',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Si no hay órdenes filtradas pero sí hay órdenes totales
            if (_filteredOrders.isEmpty) {
              return Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay órdenes con este filtro',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1000,
                    scrollController: _scrollController,
                    isHorizontalScrollBarVisible: true,
                    isVerticalScrollBarVisible: true,
                    columns: const [
                      DataColumn2(label: Text('ID'), size: ColumnSize.S),
                      DataColumn2(label: Text('Cliente'), size: ColumnSize.L),
                      DataColumn2(label: Text('Items'), size: ColumnSize.S),
                      DataColumn2(label: Text('Total'), size: ColumnSize.S),
                      DataColumn2(label: Text('Pago'), size: ColumnSize.M),
                      DataColumn2(label: Text('Fecha'), size: ColumnSize.M),
                      DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                    ],
                    rows: _buildOrderRows(),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DataRow2> _buildOrderRows() {
    // Usar órdenes ya filtradas en lugar de recalcular
    return _filteredOrders.map((order) {
      final items = order['items'] as List? ?? [];
      final customerData = order['customerId'];
      
      // El backend devuelve 'name' directamente en customerId (ya viene populado)
      final customerName = customerData is Map 
          ? (customerData['name'] ?? 'Sin nombre')
          : 'Sin cliente';

      // Generar ID corto para mostrar (últimos 8 caracteres del _id)
      final orderId = order['_id']?.toString() ?? 'N/A';
      final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

      // Método de pago
      final paymentMethod = order['paymentMethod']?.toString() ?? 'efectivo';

      return DataRow2(
        cells: [
          DataCell(Text(
            '#$shortId',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
          )),
          DataCell(
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.gray200,
                  child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(child: Text(customerName)),
              ],
            ),
          ),
          DataCell(Text('${items.length} items')),
          DataCell(Text(
            '\$${(order['totalOrden'] as num? ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
          DataCell(_buildPaymentChip(paymentMethod)),
          DataCell(Text(_formatDate(order['orderDate'] ?? order['createdAt']))),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  onPressed: () => _showOrderDetails(order),
                  tooltip: 'Ver detalles',
                ),
                IconButton(
                  icon: const Icon(Icons.print_outlined, size: 20),
                  onPressed: () {},
                  tooltip: 'Imprimir',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString() ?? 'N/A';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    
    final customerData = order['customerId'];
    final customerName = customerData is Map ? (customerData['name'] ?? 'Sin nombre') : 'Sin cliente';
    final customerPhone = customerData is Map ? (customerData['phone'] ?? '') : '';

    Get.dialog(
      AlertDialog(
        title: Text('Orden #$shortId'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cliente: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (customerPhone.isNotEmpty) Text('Teléfono: $customerPhone'),
                const SizedBox(height: 8),
                Text('Total: \$${(order['totalOrden'] as num? ?? 0).toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Método de pago: ${_getPaymentMethodText(order['paymentMethod'] as String? ?? 'efectivo')}'),
                Text('Fecha: ${_formatDate(order['orderDate'] ?? order['createdAt'])}'),
                const SizedBox(height: 16),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ...(order['items'] as List? ?? []).map((item) {
                  final product = item['productId'];
                  final productName = product is Map ? (product['name'] ?? 'Producto') : 'Producto';
                  final price = item['price'] as num? ?? 0;
                  final quantity = item['quantity'] as num? ?? 0;
                  final subtotal = price * quantity;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text('\$${price.toStringAsFixed(2)} × $quantity',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text('\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return method;
    }
  }

  Widget _buildPaymentChip(String paymentMethod) {
    Color color;
    IconData icon;
    String displayText;
    
    switch (paymentMethod.toLowerCase()) {
      case 'efectivo':
        color = AppColors.success;
        icon = Icons.attach_money;
        displayText = 'Efectivo';
        break;
      case 'tarjeta':
        color = AppColors.info;
        icon = Icons.credit_card;
        displayText = 'Tarjeta';
        break;
      case 'transferencia':
        color = AppColors.primary;
        icon = Icons.account_balance;
        displayText = 'Transferencia';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.payment;
        displayText = paymentMethod;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing12,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
