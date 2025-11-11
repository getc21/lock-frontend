import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/controllers/product_controller.dart';
import '../../shared/controllers/order_controller.dart';
import '../../shared/controllers/customer_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final orderController = Get.find<OrderController>();
    final customerController = Get.find<CustomerController>();

    return DashboardLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                     constraints.maxWidth > 768 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.spacing16,
                mainAxisSpacing: AppSizes.spacing16,
                childAspectRatio: 2.5,
                children: [
                  Obx(() {
                    final totalSales = orderController.orders.fold<double>(
                      0.0, 
                      (sum, order) => sum + (order['total'] as num? ?? order['totalOrden'] as num? ?? 0).toDouble()
                    );
                    return _buildKPICard(
                      title: 'Ventas Totales',
                      value: '\$${totalSales.toStringAsFixed(2)}',
                      change: '',
                      isPositive: true,
                      icon: Icons.attach_money,
                      color: AppColors.primary,
                    );
                  }),
                  Obx(() => _buildKPICard(
                    title: 'Órdenes',
                    value: '${orderController.orders.length}',
                    change: '',
                    isPositive: true,
                    icon: Icons.receipt_long,
                    color: AppColors.info,
                  )),
                  Obx(() => _buildKPICard(
                    title: 'Clientes',
                    value: '${customerController.customers.length}',
                    change: '',
                    isPositive: true,
                    icon: Icons.people,
                    color: AppColors.success,
                  )),
                  Obx(() => _buildKPICard(
                    title: 'Productos',
                    value: '${productController.products.length}',
                    change: '',
                    isPositive: true,
                    icon: Icons.inventory_2,
                    color: AppColors.warning,
                  )),
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
                    Expanded(
                      flex: 2,
                      child: _buildSalesChart(),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      flex: 1,
                      child: _buildTopProducts(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSalesChart(),
                    const SizedBox(height: AppSizes.spacing16),
                    _buildTopProducts(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: AppSizes.spacing32),
          
          // Recent Orders
          _buildRecentOrders(),
        ],
      ),
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
                          color: isPositive ? AppColors.success : AppColors.error,
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

  Widget _buildSalesChart() {
    final orderController = Get.find<OrderController>();
    
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
              child: Obx(() {
                // DEBUG
                if (kDebugMode) {
                  print('=== DEBUG SALES CHART ===');
                  print('Total órdenes: ${orderController.orders.length}');
                  if (orderController.orders.isNotEmpty) {
                    print('Primera orden: ${orderController.orders.first}');
                  }
                }
                
                // Agrupar órdenes por día de los últimos 30 días
                final now = DateTime.now();
                final salesByDay = List<double>.filled(30, 0.0);
                int processedOrders = 0;
                
                for (var order in orderController.orders) {
                  try {
                    final createdAt = order['createdAt'];
                    final date = order['date'];
                    final dateStr = createdAt ?? date ?? '';
                    
                    if (kDebugMode && processedOrders < 3) {
                      print('Procesando orden: createdAt=$createdAt, date=$date, dateStr=$dateStr');
                    }
                    
                    if (dateStr.isEmpty) {
                      if (kDebugMode && processedOrders < 3) {
                        print('  Orden sin fecha, saltando');
                      }
                      continue;
                    }
                    
                    final orderDate = DateTime.parse(dateStr);
                    final daysDiff = now.difference(orderDate).inDays;
                    
                    if (kDebugMode && processedOrders < 3) {
                      print('  Fecha orden: $orderDate, días diferencia: $daysDiff');
                    }
                    
                    if (daysDiff >= 0 && daysDiff < 30) {
                      final index = 29 - daysDiff; // Invertir para que el día más reciente esté a la derecha
                      final total = (order['total'] as num? ?? order['totalOrden'] as num? ?? 0).toDouble();
                      salesByDay[index] += total;
                      processedOrders++;
                      
                      if (kDebugMode && processedOrders <= 5) {
                        print('  ✅ Agregada: \$${total} en index $index (hace $daysDiff días)');
                      }
                    } else {
                      if (kDebugMode && processedOrders < 3) {
                        print('  ❌ Fuera de rango: hace $daysDiff días');
                      }
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('  ⚠️ Error procesando orden: $e');
                    }
                  }
                }
                
                if (kDebugMode) {
                  print('Total órdenes procesadas: $processedOrders');
                  print('Suma total ventas: \$${salesByDay.reduce((a, b) => a + b)}');
                  final nonZeroDays = salesByDay.where((v) => v > 0).length;
                  print('Días con ventas: $nonZeroDays de 30');
                  print('========================');
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
                            if (value.toInt() % 5 == 0 && value.toInt() >= 0 && value.toInt() < 30) {
                              final date = now.subtract(Duration(days: 29 - value.toInt()));
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
                            if (value >= 1000) {
                              return Text(
                                '\$${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }
                            return Text(
                              '\$${value.toStringAsFixed(0)}',
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
                        spots: List.generate(30, (index) => FlSpot(index.toDouble(), salesByDay[index])),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false), // Ocultar puntos para no saturar
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final orderController = Get.find<OrderController>();
    
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
            Obx(() {
              // DEBUG
              if (kDebugMode) {
                print('=== DEBUG TOP PRODUCTOS ===');
                print('Total órdenes para productos: ${orderController.orders.length}');
              }
              
              // Calcular ventas por producto
              final Map<String, Map<String, dynamic>> productSales = {};
              
              for (var order in orderController.orders) {
                final items = order['items'] as List? ?? [];
                
                if (kDebugMode && items.isNotEmpty) {
                  print('Orden ${order['_id']?.substring(0, 6)}: ${items.length} items');
                }
                
                for (var item in items) {
                  final productName = item['productId']?['name'] ?? 'Producto desconocido';
                  final quantity = (item['quantity'] as num? ?? 0).toInt();
                  final price = (item['price'] as num? ?? 0).toDouble();
                  final revenue = quantity * price;
                  
                  if (kDebugMode) {
                    print('  - $productName: $quantity x \$$price = \$$revenue');
                  }
                  
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
              
              if (kDebugMode) {
                print('Total productos únicos: ${productSales.length}');
                print('===========================');
              }
              
              // Ordenar por ventas y tomar los top 5
              final topProducts = productSales.values.toList()
                ..sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));
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
                children: top5.map((product) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
                        '\$${(product['revenue'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final orderController = Get.find<OrderController>();
    
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
                  onPressed: () => Get.toNamed('/orders'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Obx(() {
              // DEBUG
              if (kDebugMode) {
                print('=== DEBUG ÓRDENES RECIENTES ===');
                print('Total órdenes: ${orderController.orders.length}');
                if (orderController.orders.isNotEmpty) {
                  final firstOrder = orderController.orders.first;
                  print('Primera orden completa: $firstOrder');
                }
                print('================================');
              }
              
              // Tomar las últimas 5 órdenes
              final recentOrders = orderController.orders.take(5).toList();
              
              if (recentOrders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.spacing16),
                  child: Text(
                    'No hay órdenes recientes',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
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
                    final customerName = order['customerId']?['name'] ?? 'Cliente';
                    final items = order['items'] as List? ?? [];
                    final itemsCount = items.length;
                    final total = (order['total'] as num? ?? order['totalOrden'] as num? ?? 0).toDouble();
                    final status = order['status'] ?? 'completed'; // Por defecto completado si no viene
                    final date = order['createdAt'] ?? order['orderDate'] ?? order['date'] ?? '';
                    
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
                        formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
                      } catch (e) {
                        formattedDate = date;
                      }
                    }
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          orderId,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                        )),
                        DataCell(Text(customerName)),
                        DataCell(Text('$itemsCount items')),
                        DataCell(Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacing8,
                              vertical: AppSizes.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
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
              );
            }),
          ],
        ),
      ),
    );
  }
}
