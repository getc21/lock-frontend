import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/controllers/order_controller.dart';
import 'advanced_reports_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Mes Actual';
  DateTime? _startDate;
  DateTime? _endDate;
  final OrderController _orderController = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    _setDateRangeFromPeriod();
    // Cargar órdenes si no están cargadas
    if (_orderController.orders.isEmpty) {
      _orderController.loadOrders();
    }
  }

  void _setDateRangeFromPeriod() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Hoy':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Semana':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Mes Actual':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Mes Anterior':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'Año':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Personalizado':
        // No hacer nada, el usuario seleccionará las fechas
        break;
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    if (_startDate == null || _endDate == null) {
      return _orderController.orders;
    }

    return _orderController.orders.where((order) {
      final orderDate = order['orderDate'];
      if (orderDate == null) return false;
      
      try {
        final date = orderDate is DateTime ? orderDate : DateTime.parse(orderDate.toString());
        return date.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
               date.isBefore(_endDate!.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now()) 
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _selectedPeriod = 'Personalizado';
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          _selectedPeriod = 'Personalizado';
        }
      });
    }
  }

  String _getChartTitle() {
    switch (_selectedPeriod) {
      case 'Hoy':
        return 'Ventas por Hora';
      case 'Semana':
        return 'Ventas por Día';
      case 'Mes Actual':
      case 'Mes Anterior':
        return 'Ventas por Semana';
      case 'Año':
        return 'Ventas por Mes';
      case 'Personalizado':
        if (_startDate != null && _endDate != null) {
          final difference = _endDate!.difference(_startDate!).inDays;
          if (difference <= 1) return 'Ventas por Hora';
          if (difference <= 7) return 'Ventas por Día';
          if (difference <= 31) return 'Ventas por Semana';
          return 'Ventas por Mes';
        }
        return 'Ventas';
      default:
        return 'Ventas';
    }
  }

  List<BarChartGroupData> _getChartData() {
    final filteredOrders = _getFilteredOrders();
    
    switch (_selectedPeriod) {
      case 'Hoy':
        return _getHourlyData(filteredOrders);
      case 'Semana':
        return _getDailyData(filteredOrders);
      case 'Mes Actual':
      case 'Mes Anterior':
        return _getWeeklyData(filteredOrders);
      case 'Año':
        return _getMonthlyData(filteredOrders);
      case 'Personalizado':
        if (_startDate != null && _endDate != null) {
          final difference = _endDate!.difference(_startDate!).inDays;
          if (difference <= 1) return _getHourlyData(filteredOrders);
          if (difference <= 7) return _getDailyData(filteredOrders);
          if (difference <= 31) return _getWeeklyData(filteredOrders);
          return _getMonthlyData(filteredOrders);
        }
        return [];
      default:
        return _getMonthlyData(filteredOrders);
    }
  }

  List<BarChartGroupData> _getHourlyData(List<Map<String, dynamic>> orders) {
    final hourlyData = List<double>.filled(24, 0.0);
    
    for (final order in orders) {
      final orderDate = order['orderDate'];
      if (orderDate != null) {
        try {
          final date = orderDate is DateTime ? orderDate : DateTime.parse(orderDate.toString());
          final hour = date.hour;
          hourlyData[hour] += (order['totalOrden'] as num? ?? 0).toDouble();
        } catch (e) {
          // Ignorar órdenes con fecha inválida
        }
      }
    }
    
    return List.generate(24, (index) => _buildBarGroup(index, hourlyData[index]));
  }

  List<BarChartGroupData> _getDailyData(List<Map<String, dynamic>> orders) {
    final dailyData = <int, double>{};
    
    for (final order in orders) {
      final orderDate = order['orderDate'];
      if (orderDate != null) {
        try {
          final date = orderDate is DateTime ? orderDate : DateTime.parse(orderDate.toString());
          final dayIndex = date.weekday - 1; // 0 = Lunes, 6 = Domingo
          dailyData[dayIndex] = (dailyData[dayIndex] ?? 0.0) + (order['totalOrden'] as num? ?? 0).toDouble();
        } catch (e) {
          // Ignorar órdenes con fecha inválida
        }
      }
    }
    
    return List.generate(7, (index) => _buildBarGroup(index, dailyData[index] ?? 0.0));
  }

  List<BarChartGroupData> _getWeeklyData(List<Map<String, dynamic>> orders) {
    final weeklyData = <int, double>{};
    
    for (final order in orders) {
      final orderDate = order['orderDate'];
      if (orderDate != null) {
        try {
          final date = orderDate is DateTime ? orderDate : DateTime.parse(orderDate.toString());
          final weekOfMonth = ((date.day - 1) / 7).floor();
          weeklyData[weekOfMonth] = (weeklyData[weekOfMonth] ?? 0.0) + (order['totalOrden'] as num? ?? 0).toDouble();
        } catch (e) {
          // Ignorar órdenes con fecha inválida
        }
      }
    }
    
    return List.generate(5, (index) => _buildBarGroup(index, weeklyData[index] ?? 0.0));
  }

  List<BarChartGroupData> _getMonthlyData(List<Map<String, dynamic>> orders) {
    final monthlyData = <int, double>{};
    
    for (final order in orders) {
      final orderDate = order['orderDate'];
      if (orderDate != null) {
        try {
          final date = orderDate is DateTime ? orderDate : DateTime.parse(orderDate.toString());
          final month = date.month - 1; // 0 = Enero, 11 = Diciembre
          monthlyData[month] = (monthlyData[month] ?? 0.0) + (order['totalOrden'] as num? ?? 0).toDouble();
        } catch (e) {
          // Ignorar órdenes con fecha inválida
        }
      }
    }
    
    return List.generate(12, (index) => _buildBarGroup(index, monthlyData[index] ?? 0.0));
  }

  String _getBottomTitle(int index) {
    switch (_selectedPeriod) {
      case 'Hoy':
        return '${index}h';
      case 'Semana':
        const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        return index < days.length ? days[index] : '';
      case 'Mes Actual':
      case 'Mes Anterior':
        return 'S${index + 1}';
      case 'Año':
        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        return index < months.length ? months[index] : '';
      case 'Personalizado':
        if (_startDate != null && _endDate != null) {
          final difference = _endDate!.difference(_startDate!).inDays;
          if (difference <= 1) return '${index}h';
          if (difference <= 7) {
            const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
            return index < days.length ? days[index] : '';
          }
          if (difference <= 31) return 'S${index + 1}';
          const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
          return index < months.length ? months[index] : '';
        }
        return '';
      default:
        return '';
    }
  }

  String _inferCategoryFromProduct(String productName) {
    final name = productName.toLowerCase();
    
    // Categorías de cuidado capilar
    if (name.contains('shampoo') || name.contains('champú') || 
        name.contains('acondicionador') || name.contains('mascarilla capilar') ||
        name.contains('aceite para cabello') || name.contains('spray')) {
      return 'Cuidado Capilar';
    }
    
    // Categorías de maquillaje
    if (name.contains('base') || name.contains('corrector') || 
        name.contains('máscara') || name.contains('labial') ||
        name.contains('sombras') || name.contains('rubor')) {
      return 'Maquillaje';
    }
    
    // Categorías de cuidado facial
    if (name.contains('crema') || name.contains('sérum') || 
        name.contains('limpiador') || name.contains('facial') ||
        name.contains('protector solar') || name.contains('mascarilla de arcilla')) {
      return 'Cuidado Facial';
    }
    
    // Categorías de higiene/jabones
    if (name.contains('jabón') || name.contains('jabon')) {
      return 'Higiene Personal';
    }
    
    // Categoría por defecto
    return 'Otros';
  }

  Map<String, double> _getCategorySales() {
    final filteredOrders = _getFilteredOrders();
    final categorySales = <String, double>{};
    
    for (final order in filteredOrders) {
      final items = order['items'] as List? ?? [];
      for (final item in items) {
        final productData = item['productId'];
        if (productData is Map) {
          // Intentar obtener la categoría del producto, o inferirla del nombre
          String category;
          if (productData.containsKey('category') && productData['category'] != null) {
            category = productData['category'].toString();
          } else {
            final productName = productData['name']?.toString() ?? '';
            category = _inferCategoryFromProduct(productName);
          }
          
          final quantity = item['quantity'] as num? ?? 0;
          final price = item['price'] as num? ?? 0;
          final totalSale = quantity * price;
          
          categorySales[category] = (categorySales[category] ?? 0.0) + totalSale;
        }
      }
    }
    
    return categorySales;
  }

  List<PieChartSectionData> _getCategoryChartData() {
    final categorySales = _getCategorySales();
    
    if (categorySales.isEmpty) {
      return [];
    }
    
    final total = categorySales.values.fold<double>(0.0, (sum, value) => sum + value);
    
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF795548), // Brown
    ];
    
    int colorIndex = 0;
    return categorySales.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _getCategoryLegends() {
    final categorySales = _getCategorySales();
    
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
    ];
    
    int colorIndex = 0;
    return categorySales.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return _buildLegend(
        '${entry.key} (\$${entry.value.toStringAsFixed(2)})',
        color,
      );
    }).toList();
  }

  double _getMaxY() {
    final chartData = _getChartData();
    if (chartData.isEmpty) return 1000;
    
    final maxValue = chartData
        .map((group) => group.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);
    
    // Redondear hacia arriba al siguiente múltiplo de 1000
    return ((maxValue / 1000).ceil() * 1000).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Reportes',
      currentRoute: '/reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de reportes avanzados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reportes Básicos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const AdvancedReportsPage());
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Reportes Avanzados'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing20,
                    vertical: AppSizes.spacing12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          
          // Period Selector
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedPeriod,
                items: ['Hoy', 'Semana', 'Mes Actual', 'Mes Anterior', 'Año', 'Personalizado']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                    if (value != 'Personalizado') {
                      _setDateRangeFromPeriod();
                    }
                  });
                },
              ),
              const SizedBox(width: AppSizes.spacing16),
              // Fecha Inicio
              OutlinedButton.icon(
                onPressed: () => _selectDate(true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _startDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                      : 'Fecha Inicio',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              const Text('—', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: AppSizes.spacing8),
              // Fecha Fin
              OutlinedButton.icon(
                onPressed: () => _selectDate(false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _endDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Fecha Fin',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar PDF'),
              ),
              const SizedBox(width: AppSizes.spacing12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.table_chart),
                label: const Text('Exportar Excel'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Sales Summary Cards
          Obx(() {
            // Forzar observación de la lista de órdenes
            final _ = _orderController.orders.length;
            
            final filteredOrders = _getFilteredOrders();
            final totalSales = filteredOrders.fold<double>(
              0.0, 
              (sum, order) => sum + (order['totalOrden'] as num? ?? 0).toDouble()
            );
            final totalOrders = filteredOrders.length;
            final avgTicket = totalOrders > 0 ? totalSales / totalOrders : 0.0;
            
            // Contar órdenes por método de pago (ya que no hay status)
            final cashOrders = filteredOrders
                .where((o) => o['paymentMethod'] == 'efectivo')
                .length;

            return GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSizes.spacing16,
              mainAxisSpacing: AppSizes.spacing16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Ventas Totales', '\$${totalSales.toStringAsFixed(2)}', '', Icons.trending_up, AppColors.primary),
                _buildMetricCard('Total Órdenes', '$totalOrders', '', Icons.receipt_long, AppColors.info),
                _buildMetricCard('Ticket Promedio', '\$${avgTicket.toStringAsFixed(2)}', '', Icons.attach_money, AppColors.success),
                _buildMetricCard('Pagos en Efectivo', '$cashOrders', '', Icons.money, AppColors.warning),
              ],
            );
          }),
          const SizedBox(height: AppSizes.spacing32),
          
          // Sales Chart
          Obx(() {
            // Forzar observación de la lista de órdenes
            final _ = _orderController.orders.length;
            
            final chartTitle = _getChartTitle();
            final chartData = _getChartData();
            final maxY = _getMaxY();
            
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing24),
                    SizedBox(
                      height: 300,
                      child: chartData.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay datos para mostrar en este período',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY > 0 ? maxY : 1000,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '\$${rod.toY.toStringAsFixed(2)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _getBottomTitle(value.toInt()),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) {
                                        if (value == 0) return const Text('');
                                        return Text(
                                          '\$${(value / 1000).toStringAsFixed(0)}k',
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
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: maxY > 0 ? maxY / 5 : 1000,
                                  getDrawingHorizontalLine: (value) {
                                    return const FlLine(
                                      color: AppColors.border,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: chartData,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSizes.spacing24),
          
          // Category Distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ventas por Categoría',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing24),
                        Obx(() {
                          final chartData = _getCategoryChartData();
                          
                          if (chartData.isEmpty) {
                            return const SizedBox(
                              height: 250,
                              child: Center(
                                child: Text(
                                  'No hay datos de categorías en este período',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(
                                    sections: chartData,
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 0,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        // Opcional: agregar interactividad
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing16),
                              ..._getCategoryLegends(),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              Expanded(
                child: Card(
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
                          final filteredOrders = _getFilteredOrders();
                          
                          // Calcular productos más vendidos en el período
                          final productSales = <String, Map<String, dynamic>>{};
                          
                          for (final order in filteredOrders) {
                            final items = order['items'] as List? ?? [];
                            for (final item in items) {
                              final productData = item['productId'];
                              if (productData is Map) {
                                final productId = productData['_id']?.toString() ?? '';
                                final productName = productData['name']?.toString() ?? 'Sin nombre';
                                final quantity = item['quantity'] as num? ?? 0;
                                final price = item['price'] as num? ?? 0;
                                final totalSale = quantity * price;
                                
                                if (productSales.containsKey(productId)) {
                                  productSales[productId]!['totalSales'] += totalSale;
                                  productSales[productId]!['quantity'] += quantity;
                                } else {
                                  productSales[productId] = {
                                    'name': productName,
                                    'totalSales': totalSale.toDouble(),
                                    'quantity': quantity.toInt(),
                                  };
                                }
                              }
                            }
                          }
                          
                          // Ordenar por ventas totales
                          final sortedProducts = productSales.entries.toList()
                            ..sort((a, b) => b.value['totalSales'].compareTo(a.value['totalSales']));
                          
                          final topProducts = sortedProducts.take(5).toList();
                          
                          if (topProducts.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSizes.spacing24),
                                child: Text(
                                  'No hay datos en este período',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            children: topProducts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final product = entry.value.value;
                              return _buildProductRow(
                                product['name'],
                                '\$${product['totalSales'].toStringAsFixed(2)}',
                                index + 1,
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    change,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: AppColors.primary,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProductRow(String name, String sales, int position) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: position <= 3 ? AppColors.warning.withOpacity(0.2) : AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: position <= 3 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            sales,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
