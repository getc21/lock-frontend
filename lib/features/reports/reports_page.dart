import 'package:bellezapp_web/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/order_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/services/pdf_export_service.dart';
import 'advanced_reports_page.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _selectedPeriod = 'Mes Actual';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDatePickerOpen = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _setDateRangeFromPeriod();
    // Cargar órdenes si no están cargadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        ref.read(orderProvider.notifier).loadOrders();
      }
    });
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
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

  List<Map<String, dynamic>> _getFilteredOrders(OrderState orderState) {
    if (_startDate == null || _endDate == null) {
      return orderState.orders;
    }

    return orderState.orders.where((order) {
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
    final now = DateTime.now();
    // Capturar el FocusScope antes del await
    final focusScope = FocusScope.of(context);
    
    // Marcar que el date picker está abierto para desactivar touch en chart
    setState(() {
      _isDatePickerOpen = true;
    });
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? now) 
          : (_endDate != null && _endDate!.isBefore(now) ? _endDate : now),
      firstDate: DateTime(2020),
      lastDate: isStartDate ? now : DateTime(2100), // Permitir fechas futuras para endDate
      locale: const Locale('es', 'ES'),
      confirmText: 'Seleccionar', // Cambiar texto del botón
    );
    
    // Marcar que el date picker se cerró
    if (mounted) {
      setState(() {
        _isDatePickerOpen = false;
      });
    }
    
    if (mounted && picked != null) {
      // Use Future.microtask to avoid state updates during frame rendering
      Future.microtask(() {
        if (mounted) {
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
      });
      
      // Remover el foco de cualquier widget DESPUÉS del setState
      if (mounted) {
        focusScope.unfocus();
      }
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

  List<FlSpot> _getChartData(OrderState orderState) {
    final filteredOrders = _getFilteredOrders(orderState);
    
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



  List<FlSpot> _getHourlyData(List<Map<String, dynamic>> orders) {
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
    
    return List.generate(24, (index) => FlSpot(index.toDouble(), hourlyData[index]));
  }

  List<FlSpot> _getDailyData(List<Map<String, dynamic>> orders) {
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
    
    return List.generate(7, (index) => FlSpot(index.toDouble(), dailyData[index] ?? 0.0));
  }

  List<FlSpot> _getWeeklyData(List<Map<String, dynamic>> orders) {
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
    
    return List.generate(5, (index) => FlSpot(index.toDouble(), weeklyData[index] ?? 0.0));
  }

  List<FlSpot> _getMonthlyData(List<Map<String, dynamic>> orders) {
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
    
    return List.generate(12, (index) => FlSpot(index.toDouble(), monthlyData[index] ?? 0.0));
  }

  String _getBottomTitle(int index, int baseGroupCount) {
    if (index < 0 || index >= baseGroupCount) {
      return '';
    }
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

  Map<String, double> _getCategorySales(OrderState orderState) {
    final filteredOrders = _getFilteredOrders(orderState);
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

  List<PieChartSectionData> _getCategoryChartData(OrderState orderState) {
    final categorySales = _getCategorySales(orderState);
    
    if (categorySales.isEmpty) {
      return [];
    }
    
    final total = categorySales.values.fold<double>(0.0, (sum, value) => sum + value);
    
    final colors = [
      Theme.of(context).primaryColor,
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

  List<Widget> _getCategoryLegends(OrderState orderState) {
    final categorySales = _getCategorySales(orderState);
    
    final colors = [
      Theme.of(context).primaryColor,
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
        '${entry.key} (${_formatCurrency(entry.value)})',
        color,
      );
    }).toList();
  }

  double _getMaxY(List<FlSpot> chartData) {
    if (chartData.isEmpty) return 1000;
    
    final maxValue = chartData
        .map((spot) => spot.y)
        .reduce((a, b) => a > b ? a : b);
    
    // Redondear hacia arriba al siguiente múltiplo de 1000
    return ((maxValue / 1000).ceil() * 1000).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda
    
    // Mostrar loading si está cargando órdenes
    if (orderState.isLoading) {
      return DashboardLayout(
        title: 'Reportes',
        currentRoute: '/reports',
        child: LoadingIndicator(
          message: 'Cargando reportes...',
          color: Theme.of(context).primaryColor,
        ),
      );
    }
    
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
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdvancedReportsPage()));
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Reportes Avanzados'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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
                  // Use Future.microtask to avoid state updates during frame rendering
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _selectedPeriod = value!;
                        if (value != 'Personalizado') {
                          _setDateRangeFromPeriod();
                        }
                      });
                    }
                  });
                },
              ),
              const SizedBox(width: AppSizes.spacing16),
              // Fecha Inicio
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () => _exportToPdf(),
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar PDF'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Sales Summary Cards
          _buildSummaryCards(orderState),
          const SizedBox(height: AppSizes.spacing32),
          
          // Sales Chart
          _buildSalesChart(orderState),
          const SizedBox(height: AppSizes.spacing24),
          
          // Category Distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCategoryChart(orderState),
              ),
              const SizedBox(width: AppSizes.spacing16),
              Expanded(
                child: _buildTopProductsChart(orderState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(OrderState orderState) {
    final filteredOrders = _getFilteredOrders(orderState);
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
    final transferOrders = filteredOrders
        .where((o) => o['paymentMethod'] == 'transferencia')
        .length;

    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSizes.spacing16,
      mainAxisSpacing: AppSizes.spacing16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Ventas Totales', _formatCurrency(totalSales), '', Icons.trending_up, Theme.of(context).primaryColor),
        _buildMetricCard('Total Órdenes', '$totalOrders', '', Icons.receipt_long, AppColors.info),
        _buildMetricCard('Ticket Promedio', _formatCurrency(avgTicket), '', Icons.attach_money, AppColors.success),
        _buildMetricCard('Pagos en Efectivo', '$cashOrders', '', Icons.money, AppColors.warning),
        _buildMetricCard('Pagos por Transferencia', '$transferOrders', '', Icons.account_balance, AppColors.error),
      ],
    );
  }

  Widget _buildSalesChart(OrderState orderState) {
    final chartTitle = _getChartTitle();
    final baseChartData = _getChartData(orderState);
    final maxY = _getMaxY(baseChartData);
    
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
              child: baseChartData.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay datos para mostrar en este período',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        maxY: maxY > 0 ? maxY : 1000,
                        minY: 0,
                        lineTouchData: LineTouchData(
                          enabled: !_isDatePickerOpen,
                          touchCallback: (event, response) {
                            // Prevent state updates during touch events that might interfere with rendering
                          },
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              try {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    _formatCurrency(spot.y),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              } catch (e) {
                                return [];
                              }
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
                                    _getBottomTitle(value.toInt(), baseChartData.length),
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
                                final currencyNotifier = ref.read(currencyProvider.notifier);
                                final abbreviatedValue = (value / 1000).toStringAsFixed(0);
                                final formattedText = '${currencyNotifier.symbol}${abbreviatedValue}k';
                                return Text(
                                  formattedText,
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
                        lineBarsData: [
                          LineChartBarData(
                            spots: baseChartData,
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(OrderState orderState) {
    final chartData = _getCategoryChartData(orderState);
    
    return Card(
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
            if (chartData.isEmpty)
              const SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'No hay datos de categorías en este período',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Column(
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
                  ..._getCategoryLegends(orderState),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(OrderState orderState) {
    final filteredOrders = _getFilteredOrders(orderState);
    
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
            if (topProducts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.spacing24),
                  child: Text(
                    'No hay datos en este período',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Column(
                children: topProducts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value.value;
                  return _buildProductRow(
                    product['name'],
                    _formatCurrency(product['totalSales']),
                    index + 1,
                  );
                }).toList(),
              ),
          ],
        ),
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
                    color: AppColors.success.withValues(alpha: 0.1),
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
              color: position <= 3 ? AppColors.warning.withValues(alpha: 0.2) : AppColors.gray100,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparando reporte en PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      final orderState = ref.read(orderProvider);
      final filteredOrders = _getFilteredOrders(orderState);
      final totalSales = filteredOrders.fold<double>(
        0.0,
        (sum, order) => sum + (order['totalOrden'] as num? ?? 0).toDouble(),
      );
      final totalOrders = filteredOrders.length;
      final avgTicket = totalOrders > 0 ? totalSales / totalOrders : 0.0;
      final cashOrders = filteredOrders
          .where((o) => o['paymentMethod'] == 'efectivo')
          .length;

      // Obtener productos top
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

      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value['totalSales'].compareTo(a.value['totalSales']));
      final topProducts = sortedProducts.take(5).toList();

      // Exportar PDF
      final filePath = await PdfExportService.exportReportsToPdf(
        title: 'Reporte de Ventas',
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        totalSales: totalSales,
        totalOrders: totalOrders,
        avgTicket: avgTicket,
        cashOrders: cashOrders,
        categorySales: _getCategorySales(orderState),
        topProducts: topProducts
            .map((entry) => {
                  'name': entry.value['name'],
                  'totalSales': entry.value['totalSales'],
                })
            .toList(),
      );

      // Abrir PDF
      await OpenFilex.open(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte PDF generado correctamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
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
}

