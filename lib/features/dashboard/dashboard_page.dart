import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/order_notifier.dart';
import '../../shared/providers/riverpod/customer_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart' show storeProvider;
import '../../shared/providers/riverpod/currency_notifier.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Cargar datos EN PARALELO pero CON PRIORIDAD
    // Esto es mucho más rápido que cargas secuenciales
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final storeNotifier = ref.read(storeProvider.notifier);
      final orderNotifier = ref.read(orderProvider.notifier);
      final customerNotifier = ref.read(customerProvider.notifier);
      final productNotifier = ref.read(productProvider.notifier);

      // 1️⃣ CRÍTICO: Asegurar que la tienda esté cargada
      await storeNotifier.loadStores(autoSelect: true);

      if (!mounted) return;

      // 2️⃣ PARALELO: Cargar datos críticos simultáneamente
      // Esto es 3-4x más rápido que secuencial
      await Future.wait([
        orderNotifier.loadOrdersForCurrentStore(),
        customerNotifier.loadCustomersForCurrentStore(),
        productNotifier.loadProductsForCurrentStore(),
      ]);

      if (!mounted) return;

      // 3️⃣ BACKGROUND: Precarga de datos secundarios (si es necesario)
      // Esto NO bloquea la UI
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          // Precarga opcional de datos menos críticos
          // Se ejecuta en background sin afectar UX
        }
      });
    });
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final orderState = ref.watch(orderProvider);
    final customerState = ref.watch(customerProvider);
    ref.watch(currencyProvider);
    
    // Recargar datos cuando cambia la tienda actual
    ref.listen(
      storeProvider.select((state) => state.currentStore?['_id']),
      (previous, next) {
        if (previous != null && next != null && previous != next) {
          // La tienda cambió, recargar datos
          ref.read(orderProvider.notifier).loadOrdersForCurrentStore();
          ref.read(customerProvider.notifier).loadCustomersForCurrentStore();
          ref.read(productProvider.notifier).loadProductsForCurrentStore();
        }
      },
    );

    return DashboardLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 768
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.spacing16,
                mainAxisSpacing: AppSizes.spacing16,
                childAspectRatio: 2.5,
                children: [
                  _buildTotalSalesCard(orderState),
                  _buildOrderCountCard(orderState),
                  _buildCustomerCountCard(customerState),
                  _buildProductCountCard(productState),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Charts Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSalesChart(orderState)),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(flex: 1, child: _buildTopProducts(orderState)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSalesChart(orderState),
                    const SizedBox(height: AppSizes.spacing16),
                    _buildTopProducts(orderState),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: AppSizes.spacing32),

          // Recent Orders
          _buildRecentOrders(context, orderState),
        ],
      ),
    );
  }

  Widget _buildTotalSalesCard(OrderState orderState) {
    final totalSales = orderState.orders.fold<double>(
      0.0,
      (sum, order) =>
          sum +
          (order['total'] as num? ?? order['totalOrden'] as num? ?? 0)
              .toDouble(),
    );
    return _buildKPICard(
      title: 'Ventas Totales',
      value: _formatCurrency(totalSales),
      change: '',
      isPositive: true,
      icon: Icons.attach_money,
      color: Theme.of(context).primaryColor,
    );
  }

  Widget _buildOrderCountCard(OrderState orderState) {
    return _buildKPICard(
      title: 'Órdenes',
      value: '${orderState.orders.length}',
      change: '',
      isPositive: true,
      icon: Icons.receipt_long,
      color: AppColors.info,
    );
  }

  Widget _buildCustomerCountCard(CustomerState customerState) {
    return _buildKPICard(
      title: 'Clientes',
      value: '${customerState.customers.length}',
      change: '',
      isPositive: true,
      icon: Icons.people,
      color: AppColors.success,
    );
  }

  Widget _buildProductCountCard(ProductState productState) {
    return _buildKPICard(
      title: 'Productos',
      value: '${productState.products.length}',
      change: '',
      isPositive: true,
      icon: Icons.inventory_2,
      color: AppColors.warning,
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: AppSizes.spacing4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPositive
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' vs mes anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(OrderState orderState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas Últimos 30 Días',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing24),
            SizedBox(
              height: 300,
              child: _buildSalesChartContent(orderState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChartContent(OrderState orderState) {
    // Agrupar órdenes por día de los últimos 30 días
    final now = DateTime.now();
    final salesByDay = List<double>.filled(30, 0.0);

    for (var order in orderState.orders) {
      try {
        final createdAt = order['createdAt'];
        final date = order['date'];
        final dateStr = createdAt ?? date ?? '';

        if (dateStr.isEmpty) {
          continue;
        }

        final orderDate = DateTime.parse(dateStr);
        final daysDiff = now.difference(orderDate).inDays;

        if (daysDiff >= 0 && daysDiff < 30) {
          final index =
              29 - daysDiff; // Invertir para que el día más reciente esté a la derecha
          final total = (order['total'] as num? ??
                  order['totalOrden'] as num? ??
                  0)
              .toDouble();
          salesByDay[index] += total;
        }
      } catch (e) {
        // Silenciado
      }
    }

    // Calcular el máximo para el intervalo del eje Y
    final maxSales = salesByDay.reduce((a, b) => a > b ? a : b);
    final interval = maxSales > 0 ? (maxSales / 4).ceilToDouble() : 1000.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5, // Mostrar cada 5 días
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 &&
                    value.toInt() >= 0 &&
                    value.toInt() < 30) {
                  final date = now.subtract(
                    Duration(days: 29 - value.toInt()),
                  );
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final currencyNotifier = ref.read(currencyProvider.notifier);
                if (value >= 1000) {
                  return Text(
                    '${currencyNotifier.symbol}${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Text(
                  '${currencyNotifier.symbol}${value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              30,
              (index) => FlSpot(index.toDouble(), salesByDay[index]),
            ),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 2,
            dotData: const FlDotData(
              show: false,
            ), // Ocultar puntos para no saturar
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(OrderState orderState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            _buildTopProductsContent(orderState),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsContent(OrderState orderState) {
    // Calcular ventas por producto
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var order in orderState.orders) {
      final items = order['items'] as List? ?? [];

      for (var item in items) {
        final productName =
            item['productId']?['name'] ?? 'Producto desconocido';
        final quantity = (item['quantity'] as num? ?? 0).toInt();
        final price = (item['price'] as num? ?? 0).toDouble();
        final revenue = quantity * price;

        if (productSales.containsKey(productName)) {
          productSales[productName]!['sales'] += quantity;
          productSales[productName]!['revenue'] += revenue;
        } else {
          productSales[productName] = {
            'name': productName,
            'sales': quantity,
            'revenue': revenue,
          };
        }
      }
    }

    // Ordenar por ventas y tomar los top 5
    final topProducts = productSales.values.toList()
      ..sort(
        (a, b) => (b['sales'] as int).compareTo(a['sales'] as int),
      );
    final top5 = topProducts.take(5).toList();

    if (top5.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacing16),
        child: Text(
          'No hay datos de ventas',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: top5
          .map(
            (product) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.spacing8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${product['sales']} ventas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(product['revenue'] as double),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecentOrders(BuildContext context, OrderState orderState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Órdenes Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.go('/orders'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            _buildRecentOrdersContent(orderState),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersContent(OrderState orderState) {
    // Tomar las últimas 5 órdenes
    final recentOrders = orderState.orders.take(5).toList();

    if (recentOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacing16),
        child: Text(
          'No hay órdenes recientes',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                columnSpacing: AppSizes.spacing24,
                horizontalMargin: 10,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Productos')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Fecha')),
                ],
                rows: recentOrders.map((order) {
                  final orderId = order['_id'] ?? 'N/A';
                  final customerName =
                      order['customerId']?['name'] ?? 'Cliente';
                  final items = order['items'] as List? ?? [];
                  final itemsCount = items.length;
                  final total = (order['total'] as num? ??
                          order['totalOrden'] as num? ??
                          0)
                      .toDouble();
                  final status =
                      order['status'] ??
                      'completed'; // Por defecto completado si no viene
                  final date = order['createdAt'] ??
                      order['orderDate'] ??
                      order['date'] ??
                      '';

                  String statusText;
                  Color statusColor;

                  switch (status.toLowerCase()) {
                    case 'completed':
                      statusText = 'Completado';
                      statusColor = AppColors.success;
                      break;
                    case 'pending':
                      statusText = 'Pendiente';
                      statusColor = AppColors.warning;
                      break;
                    case 'processing':
                      statusText = 'Procesando';
                      statusColor = AppColors.info;
                      break;
                    case 'cancelled':
                      statusText = 'Cancelado';
                      statusColor = AppColors.error;
                      break;
                    default:
                      statusText = status;
                      statusColor = AppColors.textSecondary;
                  }

                  String formattedDate = 'N/A';
                  if (date.isNotEmpty) {
                    try {
                      final dateTime = DateTime.parse(date);
                      formattedDate =
                          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
                    } catch (e) {
                      formattedDate = date;
                    }
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          orderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      DataCell(Text(customerName)),
                      DataCell(Text('$itemsCount items')),
                      DataCell(
                        Text(
                          _formatCurrency(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing8,
                            vertical: AppSizes.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall,
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(formattedDate)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
