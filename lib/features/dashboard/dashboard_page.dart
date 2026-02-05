import 'package:bellezapp_web/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _previousStartDate;
  late DateTime _previousEndDate;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _initializeDateRanges();
    
    // Diferir la carga de datos hasta después de que el árbol de widgets termine de construirse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _initializeDateRanges() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
    
    _previousEndDate = _startDate.subtract(const Duration(days: 1));
    _previousStartDate = _previousEndDate.subtract(const Duration(days: 30));
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    final storeNotifier = ref.read(storeProvider.notifier);
    final orderNotifier = ref.read(orderProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);
    final productNotifier = ref.read(productProvider.notifier);

    await storeNotifier.loadStores(autoSelect: true);
    if (!mounted) return;

    await Future.wait([
      orderNotifier.loadOrdersForCurrentStore(),
      customerNotifier.loadCustomersForCurrentStore(),
      productNotifier.loadProductsForCurrentStore(),
    ]);

    if (mounted) {
      setState(() {
        _lastRefresh = DateTime.now();
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _previousEndDate = _startDate.subtract(const Duration(days: 1));
        _previousStartDate = _previousEndDate.subtract(
          Duration(days: _endDate.difference(_startDate).inDays),
        );
      });
    }
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  List<Map<String, dynamic>> _getOrdersInDateRange(List orders, DateTime start, DateTime end) {
    return orders.where((order) {
      try {
        final dateStr = order['createdAt'] ?? order['date'] ?? '';
        if (dateStr.isEmpty) return false;
        final orderDate = DateTime.parse(dateStr);
        // Comparar solo los días, no la hora
        final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        return !orderDay.isBefore(startDay) && !orderDay.isAfter(endDay);
      } catch (e) {
        return false;
      }
    }).cast<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final orderState = ref.watch(orderProvider);
    final customerState = ref.watch(customerProvider);
    ref.watch(currencyProvider);
    
    ref.listen(
      storeProvider.select((state) => state.currentStore?['_id']),
      (previous, next) {
        if (previous != null && next != null && previous != next) {
          _loadDashboardData();
        }
      },
    );

    if (productState.isLoading || orderState.isLoading || customerState.isLoading) {
      return DashboardLayout(
        title: 'Dashboard',
        currentRoute: '/dashboard',
        child: LoadingIndicator(
          message: 'Cargando datos del dashboard...',
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    // Debug: Mostrar datos disponibles

    final currentPeriodOrders = _getOrdersInDateRange(
      orderState.orders,
      _startDate,
      _endDate,
    );
    final previousPeriodOrders = _getOrdersInDateRange(
      orderState.orders,
      _previousStartDate,
      _previousEndDate,
    );

    return DashboardLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con período y refresh
            _buildHeader(context),
            const SizedBox(height: AppSizes.spacing24),

            // Alertas
            if (_buildAlerts(orderState.orders, productState.products).isNotEmpty)
              ..._buildAlerts(orderState.orders, productState.products),

            const SizedBox(height: AppSizes.spacing24),

            // KPI Cards mejoradas
            _buildKPICardsRow(
              currentPeriodOrders,
              previousPeriodOrders,
              customerState.customers,
            ),
            const SizedBox(height: AppSizes.spacing32),

            // Charts Row
            _buildChartsSection(currentPeriodOrders, orderState.orders),
            const SizedBox(height: AppSizes.spacing32),

            // Análisis de pagos y clientes
            _buildPaymentAndCustomersSection(
              currentPeriodOrders,
              customerState.customers,
            ),
            const SizedBox(height: AppSizes.spacing32),

            // Top productos y órdenes recientes
            _buildProductsAndOrdersSection(
              currentPeriodOrders,
              orderState.orders,
              productState.products,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing12,
                      vertical: AppSizes.spacing8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Última actualización:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _lastRefresh != null
                    ? '${_lastRefresh!.hour}:${_lastRefresh!.minute.toString().padLeft(2, '0')}'
                    : 'Cargando...',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.spacing16),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: _refreshData,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlerts(List orders, List products) {
    final alerts = <Widget>[];

    // Verificar si no hay ventas hoy
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final todayOrders = _getOrdersInDateRange(orders, todayStart, todayEnd);
    
    if (todayOrders.isEmpty) {
      alerts.add(
        _buildAlertCard(
          icon: Icons.trending_down,
          title: 'Sin ventas hoy',
          message: 'No hay órdenes registradas el día de hoy',
          color: AppColors.warning,
        ),
      );
      alerts.add(const SizedBox(height: AppSizes.spacing16));
    }

    // Verificar stock bajo
    final lowStockProducts = products.where((p) {
      final stock = p['stock'] as num? ?? 0;
      return stock > 0 && stock < 10;
    }).length;

    if (lowStockProducts > 0) {
      alerts.add(
        _buildAlertCard(
          icon: Icons.warning,
          title: 'Stock bajo',
          message: '$lowStockProducts productos con menos de 10 unidades',
          color: AppColors.error,
        ),
      );
      alerts.add(const SizedBox(height: AppSizes.spacing16));
    }

    return alerts;
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICardsRow(
    List currentOrders,
    List previousOrders,
    List customers,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildKPICardWithChange(
            title: 'Ventas Totales',
            currentValue: _calculateTotalSales(currentOrders),
            previousValue: _calculateTotalSales(previousOrders),
            icon: Icons.attach_money,
            color: Theme.of(context).primaryColor,
            isCurrency: true,
          ),
          _buildKPICardWithChange(
            title: 'Órdenes',
            currentValue: currentOrders.length.toDouble(),
            previousValue: previousOrders.length.toDouble(),
            icon: Icons.receipt_long,
            color: AppColors.info,
            isCurrency: false,
          ),
          _buildKPICardWithChange(
            title: 'Ticket Promedio',
            currentValue: currentOrders.isEmpty
                ? 0
                : _calculateTotalSales(currentOrders) / currentOrders.length,
            previousValue: previousOrders.isEmpty
                ? 0
                : _calculateTotalSales(previousOrders) / previousOrders.length,
            icon: Icons.calculate,
            color: AppColors.success,
            isCurrency: true,
          ),
          _buildKPICardWithChange(
            title: 'Clientes',
            currentValue: customers.length.toDouble(),
            previousValue: customers.length.toDouble(),
            icon: Icons.people,
            color: AppColors.warning,
            isCurrency: false,
          ),
          _buildKPICardWithChange(
            title: 'Conversión',
            currentValue: customers.isEmpty
                ? 0
                : (currentOrders.length / customers.length) * 100,
            previousValue: customers.isEmpty
                ? 0
                : (previousOrders.length / customers.length) * 100,
            icon: Icons.trending_up,
            color: AppColors.success,
            isCurrency: false,
            suffix: '%',
          ),
        ];

        return Wrap(
          spacing: AppSizes.spacing16,
          runSpacing: AppSizes.spacing16,
          children: cards
              .map((card) => SizedBox(
                    width: constraints.maxWidth > 1200
                        ? (constraints.maxWidth - AppSizes.spacing16 * 4) / 5
                        : constraints.maxWidth > 900
                        ? (constraints.maxWidth - AppSizes.spacing16 * 2) / 3
                        : constraints.maxWidth > 600
                        ? (constraints.maxWidth - AppSizes.spacing16) / 2
                        : constraints.maxWidth,
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKPICardWithChange({
    required String title,
    required double currentValue,
    required double previousValue,
    required IconData icon,
    required Color color,
    required bool isCurrency,
    String suffix = '',
  }) {
    final change = previousValue == 0
        ? 0
        : ((currentValue - previousValue) / previousValue) * 100;
    final isPositive = change >= 0;

    String displayValue;
    if (isCurrency) {
      displayValue = _formatCurrency(currentValue);
    } else if (suffix.isNotEmpty) {
      displayValue = '${currentValue.toStringAsFixed(1)}$suffix';
    } else {
      displayValue = currentValue.toStringAsFixed(0);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing4,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
                const Text(
                  'vs anterior',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalSales(List orders) {
    return orders.fold<double>(0.0, (sum, order) {
      final total =
          (order['total'] as num? ?? order['totalOrden'] as num? ?? 0)
              .toDouble();
      return sum + total;
    });
  }

  Widget _buildChartsSection(List currentOrders, List allOrders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildSalesChart(currentOrders)),
              const SizedBox(width: AppSizes.spacing16),
              Expanded(flex: 1, child: _buildPaymentMethodChart(currentOrders)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSalesChart(currentOrders),
              const SizedBox(height: AppSizes.spacing16),
              _buildPaymentMethodChart(currentOrders),
            ],
          );
        }
      },
    );
  }

  Widget _buildSalesChart(List orders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas en el Período',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing24),
            SizedBox(
              height: 300,
              child: _buildSalesChartContent(orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChartContent(List orders) {
    final dayDifference = _endDate.difference(_startDate).inDays;
    final salesByDay = List<double>.filled(dayDifference + 1, 0.0);

    for (var order in orders) {
      try {
        final createdAt = order['createdAt'];
        final date = order['date'];
        final dateStr = createdAt ?? date ?? '';

        if (dateStr.isEmpty) continue;

        final orderDate = DateTime.parse(dateStr);
        final daysDiff = orderDate.difference(_startDate).inDays;

        if (daysDiff >= 0 && daysDiff <= dayDifference) {
          final total = (order['total'] as num? ??
                  order['totalOrden'] as num? ??
                  0)
              .toDouble();
          salesByDay[daysDiff] += total;
        }
      } catch (e) {
        // Silenciado
      }
    }

    final maxSales = salesByDay.isEmpty
        ? 1000
        : salesByDay.reduce((a, b) => a > b ? a : b);
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
              interval: (dayDifference / 6).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index <= dayDifference) {
                  final date = _startDate.add(Duration(days: index));
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
                final currencyNotifier =
                    ref.read(currencyProvider.notifier);
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
              dayDifference + 1,
              (index) => FlSpot(index.toDouble(), salesByDay[index]),
            ),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChart(List orders) {
    final paymentMethods = <String, double>{};

    for (var order in orders) {
      final method = (order['paymentMethod'] ?? 'Sin especificar').toString();
      final total =
          (order['total'] as num? ?? order['totalOrden'] as num? ?? 0)
              .toDouble();
      paymentMethods[method] = (paymentMethods[method] ?? 0) + total;
    }

    if (paymentMethods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            children: [
              const Text(
                'Distribución de Pagos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.spacing24),
              const Text('Sin datos de pagos'),
            ],
          ),
        ),
      );
    }

    final colors = [
      Theme.of(context).primaryColor,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Pagos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: List.generate(
                    paymentMethods.length,
                    (index) => PieChartSectionData(
                      value: paymentMethods.values.toList()[index],
                      title: paymentMethods.keys.toList()[index],
                      color: colors[index % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            ..._buildPaymentLegend(paymentMethods, colors),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPaymentLegend(
    Map<String, double> paymentMethods,
    List<Color> colors,
  ) {
    return paymentMethods.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final method = entry.value.key;
      final amount = entry.value.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.spacing8),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              _formatCurrency(amount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPaymentAndCustomersSection(
    List currentOrders,
    List customers,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTopCustomersCard(currentOrders, customers),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildConversionCard(currentOrders, customers),
        ),
      ],
    );
  }

  Widget _buildTopCustomersCard(List orders, List customers) {
    final customerSpending = <String, double>{};
    final customerIds = <String, String>{};

    for (var customer in customers) {
      customerIds[customer['_id']] = customer['name'] ?? 'Sin nombre';
    }

    for (var order in orders) {
      final customerId = order['customerId'] is Map
          ? (order['customerId'] as Map)['_id']
          : order['customerId'];
      if (customerId != null) {
        final customerName = customerIds[customerId] ?? 'Cliente Desconocido';
        final total =
            (order['total'] as num? ?? order['totalOrden'] as num? ?? 0)
                .toDouble();
        customerSpending[customerName] =
            (customerSpending[customerName] ?? 0) + total;
      }
    }

    final topCustomers = customerSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 10 Clientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            if (topCustomers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                child: Text('Sin datos de clientes'),
              )
            else
              ...topCustomers.take(10).map((entry) {
                final index = topCustomers.indexOf(entry);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Gasto: ${_formatCurrency(entry.value)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(List orders, List customers) {
    // Contar órdenes por cliente
    final customerOrderCount = <String, int>{};
    
    for (var order in orders) {
      final customerId = order['customerId'] is Map
          ? (order['customerId'] as Map)['_id']
          : order['customerId'];
      
      if (customerId != null) {
        customerOrderCount[customerId.toString()] = 
            (customerOrderCount[customerId.toString()] ?? 0) + 1;
      }
    }

    final totalOrders = orders.length;
    final uniqueCustomers = customerOrderCount.length;
    final recurringCustomers = customerOrderCount.values.where((count) => count > 1).length;
    final recurringRate = uniqueCustomers == 0
        ? 0.0
        : (recurringCustomers / uniqueCustomers) * 100;
    final avgOrdersPerCustomer = uniqueCustomers == 0
        ? 0.0
        : totalOrders / uniqueCustomers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Análisis de Clientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing24),
              _buildConversionStat(
                'Clientes Únicos',
                uniqueCustomers.toString(),
                Icons.people,
              ),
              const SizedBox(height: AppSizes.spacing16),
              _buildConversionStat(
                'Clientes Recurrentes',
                recurringCustomers.toString(),
                Icons.repeat,
              ),
              const SizedBox(height: AppSizes.spacing16),
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Clientes Recurrentes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${recurringRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            'Compras por Cliente',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          avgOrdersPerCustomer.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
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
      ),
    );
  }

  Widget _buildConversionStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsAndOrdersSection(
    List currentOrders,
    List allOrders,
    List products,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTopProductsCard(currentOrders, products),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildRecentOrdersCard(currentOrders),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(List orders, List allProducts) {
    final productSales = <String, Map<String, dynamic>>{};

    for (var order in orders) {
      final items = order['items'] as List? ?? [];
      for (var item in items) {
        var productId = item is Map ? item['productId'] : item;
        
        if (productId == null) continue;
        
        // Convertir productId a String si es necesario
        final productIdStr = productId is Map 
            ? productId['_id']?.toString() ?? productId.toString()
            : productId.toString();
        
        final quantity = (item is Map ? item['quantity'] : 1) as num? ?? 1;
        final price = (item is Map ? item['price'] : 0) as num? ?? 0;

        final product = allProducts.firstWhere(
          (p) => p['_id'] == productId || p['_id']?.toString() == productIdStr,
          orElse: () => <String, dynamic>{},
        );

        final productName = product.isNotEmpty
            ? (product['name'] ?? 'Producto desconocido').toString()
            : 'Producto desconocido';

        if (!productSales.containsKey(productIdStr)) {
          productSales[productIdStr] = {
            'name': productName,
            'quantity': 0,
            'revenue': 0.0,
            'stock': product.isNotEmpty ? (product['stock'] as num? ?? 0).toInt() : 0,
            'productId': productIdStr,
          };
        }

        productSales[productIdStr]!['quantity'] = (productSales[productIdStr]!['quantity'] as int) + quantity.toInt();
        productSales[productIdStr]!['revenue'] = (productSales[productIdStr]!['revenue'] as double) + (price * quantity).toDouble();
      }
    }

    final topProducts = productSales.values.toList()
      ..sort((a, b) =>
          (b['revenue'] as num).compareTo(a['revenue'] as num));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 20 Productos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            if (topProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacing16),
                child: Text('Sin datos de productos'),
              )
            else
              ...topProducts.take(20).map((entry) {
                final index = topProducts.indexOf(entry);
                final stock = (entry['stock'] as num? ?? 0).toInt();
                final lowStock = stock < 10;
                final productName = (entry['name'] as dynamic ?? 'Producto desconocido').toString();
                final quantity = (entry['quantity'] as num? ?? 0).toInt();
                final revenue = (entry['revenue'] as num? ?? 0.0).toDouble();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$quantity vendidos',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(revenue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Stock: $stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: lowStock ? AppColors.error : AppColors.textSecondary,
                                  fontWeight: lowStock ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (lowStock) ...[
                        const SizedBox(height: AppSizes.spacing4),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: stock / 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(List orders) {
    final recentOrders = orders.take(10).toList();

    if (recentOrders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Órdenes Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing24),
              const Center(
                child: Text('No hay órdenes recientes'),
              ),
            ],
          ),
        ),
      );
    }

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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            ...recentOrders.take(5).map((order) {
              final orderId = (order['_id'] ?? 'N/A').toString().substring(0, 8);
              final customerName =
                  order['customerId'] is Map
                      ? (order['customerId'] as Map)['name'] ?? 'Cliente'
                      : 'Cliente';
              final total = (order['total'] as num? ??
                      order['totalOrden'] as num? ??
                      0)
                  .toDouble();
              final status = order['status'] ?? 'completed';
              final date = order['createdAt'] ?? order['date'] ?? '';

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

              // Parse date if provided (for future use)
              if (date.isNotEmpty) {
                try {
                  DateTime.parse(date);
                } catch (e) {
                  // Handle date parsing error
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$orderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacing4,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

