import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/professional_loading.dart';
import '../../shared/providers/riverpod/order_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/services/pdf_service.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  String _paymentFilter = 'Todos';
  late final ScrollController _scrollController;
  int _currentPage = 0;
  static const int _itemsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Cargar órdenes cuando se abre la página (sin forzar recarga)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadOrdersForCurrentStore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualizar órdenes en background cuando volvemos (sin bloquear UI)
    // Usa caché si existe, carga nuevos datos en background
    // Envuelto en Future para no modificar el provider durante la construcción
    Future(() {
      ref.read(orderProvider.notifier).loadOrdersForCurrentStore(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observar estado de órdenes y moneda
    final orderState = ref.watch(orderProvider);
    ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda
    
    // Filtrar órdenes según el filtro de pago
    final filteredOrders = orderState.orders
        .where((o) => _paymentFilter == 'Todos' || o['paymentMethod'] == _paymentFilter)
        .toList();
    
    // Paginación
    final totalPages = (filteredOrders.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredOrders.length);
    final paginatedOrders = startIndex < filteredOrders.length 
        ? filteredOrders.sublist(startIndex, endIndex)
        : [];

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
                    _currentPage = 0; // Reset to first page
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.go('/orders/create'),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Orden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Orders Table
          if (orderState.isLoading)
            SizedBox(
              height: 600,
              child: ProfessionalLoading(
                message: 'Cargando órdenes...',
                rowCount: 8,
                columnCount: 6,
              ),
            )
          else if (orderState.orders.isEmpty)
            Card(
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
            )
          else if (filteredOrders.isEmpty)
            Card(
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
            )
          else
            Card(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.spacing16),
                      child: SizedBox(
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
                          rows: _buildOrderRows(paginatedOrders),
                        ),
                      ),
                    ),
                  ),
                  // Pagination Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing16,
                      vertical: AppSizes.spacing12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${filteredOrders.length} órdenes',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            Text(
                              'Página ${_currentPage + 1} de $totalPages',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
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
            ),
        ],
      ),
    );
  }

  List<DataRow2> _buildOrderRows(List<dynamic> paginatedOrders) {
    // Convertir órdenes paginadas a DataRow2
    return paginatedOrders.cast<Map<String, dynamic>>().map((order) {
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
            style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
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
            _formatCurrency((order['totalOrden'] as num? ?? 0).toDouble(), ref),
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
                  onPressed: () => _generateAndPrintPDF(order),
                  tooltip: 'Imprimir PDF',
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
      final localDateTime = dateTime.toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);
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
    final paymentMethod = order['paymentMethod'] as String? ?? 'efectivo';
    final totalOrden = (order['totalOrden'] as num? ?? 0).toDouble();
    final items = order['items'] as List? ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            color: AppColors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLarge),
                      topRight: Radius.circular(AppSizes.radiusLarge),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orden #$shortId',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(order['orderDate'] ?? order['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cliente Section
                      _buildDetailSection(
                        icon: Icons.person_outline,
                        title: 'Cliente',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                customerPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacing20),

                      // Payment & Total Section
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailSection(
                              icon: Icons.payment_outlined,
                              title: 'Método de pago',
                              child: _buildPaymentChip(paymentMethod),
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: _buildDetailSection(
                              icon: Icons.attach_money,
                              title: 'Total',
                              child: Text(
                                _formatCurrency(totalOrden, ref),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.spacing24),

                      // Items Section
                      Text(
                        'Productos (${items.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                            child: Text(
                              'Sin productos',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          child: Column(
                            children: items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final product = item['productId'];
                              final productName = product is Map ? (product['name'] ?? 'Producto') : 'Producto';
                              final price = item['price'] as num? ?? 0;
                              final quantity = item['quantity'] as num? ?? 0;
                              final subtotal = (price * quantity).toDouble();
                              final isLast = index == items.length - 1;

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(AppSizes.spacing12),
                                    child: Row(
                                      children: [
                                        // Product Icon
                                        Container(
                                          padding: const EdgeInsets.all(AppSizes.spacing8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                                          ),
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 20,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: AppSizes.spacing12),
                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_formatCurrency(price, ref)} × $quantity',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Subtotal
                                        Text(
                                          _formatCurrency(subtotal, ref),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(height: 1, color: AppColors.border),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Footer Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.spacing24,
                    AppSizes.spacing16,
                    AppSizes.spacing24,
                    AppSizes.spacing24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _generateAndPrintPDF(order),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Imprimir'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Listo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _generateAndPrintPDF(Map<String, dynamic> order) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      await PdfService.generateOrderPdf(order: order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error al generar PDF';
      
      // Mensajes de error más amigables
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('path') || errorStr.contains('storage') || errorStr.contains('almacenamiento')) {
        errorMessage = 'No se pudo acceder al almacenamiento. Verifica los permisos del dispositivo.';
      } else if (errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permiso denegado. Habilita permisos de almacenamiento en configuración.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(num value, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
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
        color = Theme.of(context).primaryColor;
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

