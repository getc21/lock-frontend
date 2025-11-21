import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/providers/riverpod/reports_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/services/pdf_service.dart';

class AdvancedReportsPage extends ConsumerStatefulWidget {
  const AdvancedReportsPage({super.key});

  @override
  ConsumerState<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends ConsumerState<AdvancedReportsPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedPeriod;
  late int _selectedTab;

  // No store change listener needed outside build

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _selectedPeriod = 'daily';
    _selectedTab = 0;
    
    // Cargar reportes después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReports();
      }
    });

    // Listen for store changes and reload reports
    // Use didChangeDependencies for correct context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // (removed: ref.listen must be in build)
  }

  @override
  void dispose() {
    // No listener cleanup needed
    super.dispose();
  }

  Future<void> _loadReports() async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final startDateStr = formatter.format(_startDate);
    final endDateStr = formatter.format(_endDate);

    // Cargar todos los reportes
    await ref.read(reportsProvider.notifier).loadInventoryRotationAnalysis(
      startDate: startDateStr,
      endDate: endDateStr,
      period: _selectedPeriod,
    );
    
    await ref.read(reportsProvider.notifier).loadProfitabilityAnalysis(
      startDate: startDateStr,
      endDate: endDateStr,
    );
    
    await ref.read(reportsProvider.notifier).loadSalesTrendsAnalysis(
      startDate: startDateStr,
      endDate: endDateStr,
      period: _selectedPeriod,
    );

    // Calcular período anterior para comparación
    final duration = _endDate.difference(_startDate);
    final previousEnd = _startDate.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(duration);
    
    await ref.read(reportsProvider.notifier).loadPeriodsComparison(
      currentStartDate: startDateStr,
      currentEndDate: endDateStr,
      previousStartDate: formatter.format(previousStart),
      previousEndDate: formatter.format(previousEnd),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // Capturar el FocusScope antes del await
    final focusScope = FocusScope.of(context);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      confirmText: 'Seleccionar', // Cambiar texto del botón
    );

    if (mounted && picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _loadReports();
      });
      
      // Remover el foco de cualquier widget DESPUÉS del setState
      if (mounted) {
        focusScope.unfocus();
        // Pequeño delay para asegurar que el UI se actualice completamente
        await Future.delayed(const Duration(milliseconds: 100));
      }
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
        name.contains('sombras') || name.contains('rubor') || name.contains('paleta')) {
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

  @override
  Widget build(BuildContext context) {
        // Listen for store changes and reload reports
        ref.listen<StoreState>(
          storeProvider,
          (previous, next) {
            if (previous == null || previous.currentStore?['_id'] != next.currentStore?['_id']) {
              if (mounted) {
                _loadReports();
              }
            }
          },
        );
    final reportsState = ref.watch(reportsProvider);
    ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda
    
    return DashboardLayout(
      title: 'Reportes Avanzados',
      currentRoute: '/advanced-reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controles de fecha y período
          _buildControls(),
          const SizedBox(height: AppSizes.spacing24),
          
          // Tabs
          _buildTabBar(),
          const SizedBox(height: AppSizes.spacing24),
          
          // Contenido según tab seleccionado
          if (reportsState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.spacing32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (reportsState.errorMessage.isNotEmpty)
            Card(
              color: Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Text(
                      reportsState.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    ElevatedButton.icon(
                      onPressed: _loadReports,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildTabContent(reportsState),
        ],
      ),
    );
  }

  Widget _buildTabContent(ReportsState reportsState) {
    switch (_selectedTab) {
      case 0:
        return _buildInventoryRotationTab(reportsState);
      case 1:
        return _buildProfitabilityTab(reportsState);
      case 2:
        return _buildSalesTrendsTab(reportsState);
      case 3:
        return _buildPeriodsComparisonTab(reportsState);
      default:
        return const SizedBox();
    }
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            // Fecha inicio
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha Inicio',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_startDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            
            // Fecha fin
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha Fin',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_endDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            
            // Período (solo para Tendencias)
            Expanded(
              child: Tooltip(
                message: _selectedTab != 2
                    ? 'El período solo aplica a Tendencias de Ventas'
                    : 'Agrupa los datos por día, semana o mes',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPeriod,
                  decoration: InputDecoration(
                    labelText: 'Período',
                    border: const OutlineInputBorder(),
                    enabled: _selectedTab == 2,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diario')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  ],
                  onChanged: _selectedTab == 2
                      ? (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                              _loadReports();
                            });
                          }
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            
            // Botón refrescar
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing24,
                  vertical: AppSizes.spacing16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(0, Icons.inventory_2, 'Rotación de Inventario'),
            _buildTabButton(1, Icons.attach_money, 'Rentabilidad'),
            _buildTabButton(2, Icons.trending_up, 'Tendencias'),
            _buildTabButton(3, Icons.compare_arrows, 'Comparación'),
            const SizedBox(width: AppSizes.spacing16),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final reportsState = ref.read(reportsProvider);
        
        try {
          switch (value) {
            case 'inventory':
              await PdfService.generateInventoryRotationPdf(
                data: reportsState.inventoryRotation,
                startDate: _startDate,
                endDate: _endDate,
              );
              _showSnackBar('Reporte de Rotación descargado');
              break;
            case 'profitability':
              await PdfService.generateProfitabilityPdf(
                data: reportsState.profitability,
                startDate: _startDate,
                endDate: _endDate,
              );
              _showSnackBar('Reporte de Rentabilidad descargado');
              break;
            case 'trends':
              await PdfService.generateSalesTrendsPdf(
                data: reportsState.salesTrends,
                startDate: _startDate,
                endDate: _endDate,
                period: _selectedPeriod,
              );
              _showSnackBar('Reporte de Tendencias descargado');
              break;
            case 'comparison':
              await PdfService.generateComparisonPdf(
                data: reportsState.periodsComparison,
                startDate: _startDate,
                endDate: _endDate,
              );
              _showSnackBar('Reporte Comparativo descargado');
              break;
            case 'all':
              await Future.wait([
                PdfService.generateInventoryRotationPdf(
                  data: reportsState.inventoryRotation,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                PdfService.generateProfitabilityPdf(
                  data: reportsState.profitability,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                PdfService.generateSalesTrendsPdf(
                  data: reportsState.salesTrends,
                  startDate: _startDate,
                  endDate: _endDate,
                  period: _selectedPeriod,
                ),
                PdfService.generateComparisonPdf(
                  data: reportsState.periodsComparison,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
              ]);
              _showSnackBar('Todos los reportes descargados');
              break;
          }
        } catch (e) {
          _showSnackBar('Error: ${e.toString()}', isError: true);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'inventory',
          child: Row(
            children: [
              Icon(Icons.inventory_2, size: 20),
              SizedBox(width: 10),
              Text('Rotación'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profitability',
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 20),
              SizedBox(width: 10),
              Text('Rentabilidad'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'trends',
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20),
              SizedBox(width: 10),
              Text('Tendencias'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'comparison',
          child: Row(
            children: [
              Icon(Icons.compare_arrows, size: 20),
              SizedBox(width: 10),
              Text('Comparación'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Icon(Icons.description, size: 20),
              SizedBox(width: 10),
              Text('Todos los reportes'),
            ],
          ),
        ),
      ],
      child: Tooltip(
        message: 'Exportar a PDF',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing12,
          ),
          child: Row(
            children: [
              const Icon(Icons.file_download),
              const SizedBox(width: AppSizes.spacing8),
              const Text('Exportar'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing16,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryRotationTab(ReportsState reportsState) {
    final data = reportsState.inventoryRotation;
    
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];

    return Column(
      children: [
        // Resumen
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Rotación Promedio',
                '${summary['averageRotationRate']?.toStringAsFixed(2) ?? '0'} veces',
                Icons.loop,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Productos Activos',
                '${summary['totalProducts'] ?? 0}',
                Icons.inventory,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Productos Rápidos',
                '${summary['fastMovingProducts'] ?? 0}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Productos Lentos',
                '${summary['slowMovingProducts'] ?? 0}',
                Icons.trending_down,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing24),
        
        // Tabla de productos
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSizes.spacing16),
                child: Text(
                  'Análisis por Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Stock Actual')),
                    DataColumn(label: Text('Vendidos')),
                    DataColumn(label: Text('Tasa Rotación')),
                    DataColumn(label: Text('Días p/ Vender')),
                    DataColumn(label: Text('Estado')),
                  ],
                  rows: products.map<DataRow>((product) {
                    final daysToSell = product['daysToSellStock'] ?? 0;
                    final rotationRate = product['rotationRate'] ?? 0;
                    final statusText = product['status'] ?? 'normal';
                    final productName = product['productName'] ?? '';
                    final category = product['category'] == 'Sin categoría' || product['category'] == null
                        ? _inferCategoryFromProduct(productName)
                        : product['category'];
                    
                    String statusLabel;
                    Color statusColor;
                    
                    switch (statusText) {
                      case 'fast':
                        statusLabel = 'Rápido';
                        statusColor = Colors.green;
                        break;
                      case 'slow':
                        statusLabel = 'Lento';
                        statusColor = Colors.red;
                        break;
                      default:
                        statusLabel = 'Normal';
                        statusColor = Colors.orange;
                    }

                    return DataRow(cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            productName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(category)),
                      DataCell(Text('${product['currentStock'] ?? 0}')),
                      DataCell(Text('${product['totalSold'] ?? 0}')),
                      DataCell(Text('${rotationRate.toStringAsFixed(2)}x')),
                      DataCell(Text('${daysToSell.toStringAsFixed(1)} días')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitabilityTab(ReportsState reportsState) {
    final data = reportsState.profitability;
    
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];

    return Column(
      children: [
        // Resumen financiero
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ventas Totales',
                _formatCurrency((summary['totalRevenue'] ?? 0) as num),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Ganancia',
                _formatCurrency((summary['totalProfit'] ?? 0) as num),
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Margen Promedio',
                '${(summary['averageProfitMargin'] ?? 0).toStringAsFixed(1)}%',
                Icons.percent,
                Colors.purple,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Productos',
                '${summary['productCount'] ?? 0}',
                Icons.inventory_2,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing24),
        
        // Tabla de rentabilidad por producto
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSizes.spacing16),
                child: Text(
                  'Rentabilidad por Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Cantidad')),
                    DataColumn(label: Text('Órdenes')),
                    DataColumn(label: Text('Ingresos')),
                    DataColumn(label: Text('Costo')),
                    DataColumn(label: Text('Ganancia')),
                    DataColumn(label: Text('Margen %')),
                    DataColumn(label: Text('% Ventas')),
                  ],
                  rows: products.map<DataRow>((product) {
                    final margin = product['profitMargin'] ?? 0;
                    final productName = product['productName'] ?? '';
                    final category = product['category'] == 'Sin categoría' || product['category'] == null
                        ? _inferCategoryFromProduct(productName)
                        : product['category'];
                    
                    return DataRow(cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            productName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(category)),
                      DataCell(Text('${product['totalQuantity'] ?? 0}')),
                      DataCell(Text('${product['orderCount'] ?? 0}')),
                      DataCell(Text(_formatCurrency((product['totalRevenue'] ?? 0) as num))),
                      DataCell(Text(_formatCurrency((product['totalCost'] ?? 0) as num))),
                      DataCell(Text(_formatCurrency((product['totalProfit'] ?? 0) as num))),
                      DataCell(
                        Text(
                          '${margin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: margin > 50 ? Colors.green : margin > 30 ? Colors.orange : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text('${(product['revenuePercentage'] ?? 0).toStringAsFixed(1)}%'),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesTrendsTab(ReportsState reportsState) {
    final data = reportsState.salesTrends;
    
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final trends = data['trends'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Resumen de tendencias
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ventas Totales',
                _formatCurrency((summary['totalRevenue'] ?? 0) as num),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Total Órdenes',
                '${summary['totalOrders'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Promedio Diario',
                _formatCurrency((summary['averageDaily'] ?? 0) as num),
                Icons.analytics,
                Colors.purple,
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: _buildMetricCard(
                'Valor Promedio',
                _formatCurrency((summary['averageOrderValue'] ?? 0) as num),
                Icons.receipt,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing24),
        
        // Gráfico de tendencias
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tendencia de Ventas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),
                SizedBox(
                  height: 300,
                  child: trends.isEmpty 
                      ? const Center(
                          child: Text('No hay suficientes datos para mostrar el gráfico'),
                        )
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < trends.length) {
                                final trend = trends[value.toInt()];
                                final period = trend['period'] ?? '';
                                // Mostrar solo la fecha en formato corto
                                try {
                                  final date = DateTime.parse(period.toString());
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${date.day}/${date.month}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                } catch (e) {
                                  return Text(
                                    period.toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                              }
                              return const Text('');
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
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trends.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['totalRevenue'] ?? 0).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacing24),
        
        // Tabla de detalles
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSizes.spacing16),
                child: Text(
                  'Detalles por Período',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Período')),
                    DataColumn(label: Text('Órdenes')),
                    DataColumn(label: Text('Ingresos')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Valor Promedio')),
                  ],
                  rows: trends.map<DataRow>((trend) {
                    final period = trend['period'] ?? '';
                    String formattedPeriod;
                    try {
                      final date = DateTime.parse(period.toString());
                      formattedPeriod = DateFormat('dd/MM/yyyy').format(date);
                    } catch (e) {
                      formattedPeriod = period.toString();
                    }
                    
                    return DataRow(cells: [
                      DataCell(Text(formattedPeriod)),
                      DataCell(Text('${trend['orderCount'] ?? 0}')),
                      DataCell(Text(_formatCurrency((trend['totalRevenue'] ?? 0) as num))),
                      DataCell(Text('${trend['totalItems'] ?? 0}')),
                      DataCell(Text(_formatCurrency((trend['averageOrderValue'] ?? 0) as num))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodsComparisonTab(ReportsState reportsState) {
    final data = reportsState.periodsComparison;
    
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final comparison = data['comparison'] as Map<String, dynamic>? ?? {};
    final current = comparison['currentPeriod'] as Map<String, dynamic>? ?? {};
    final previous = comparison['previousPeriod'] as Map<String, dynamic>? ?? {};
    final productComparisons = data['productComparisons'] as List? ?? [];

    return Column(
      children: [
        // Comparación de métricas principales
        _buildComparisonCard(
          'Ventas Totales',
          current['totalSales'] ?? 0,
          previous['totalSales'] ?? 0,
          comparison['salesGrowth'] ?? 0,
          Icons.attach_money,
        ),
        const SizedBox(height: AppSizes.spacing16),
        
        _buildComparisonCard(
          'Número de Órdenes',
          current['totalOrders'] ?? 0,
          previous['totalOrders'] ?? 0,
          comparison['ordersGrowth'] ?? 0,
          Icons.shopping_cart,
          isCurrency: false,
        ),
        const SizedBox(height: AppSizes.spacing16),
        
        _buildComparisonCard(
          'Ticket Promedio',
          current['averageOrderValue'] ?? 0,
          previous['averageOrderValue'] ?? 0,
          comparison['avgOrderValueGrowth'] ?? 0,
          Icons.receipt,
          isCurrency: true,
        ),
        const SizedBox(height: AppSizes.spacing16),
        
        _buildComparisonCard(
          'Total Items',
          current['totalItems'] ?? 0,
          previous['totalItems'] ?? 0,
          0, // No hay campo de crecimiento para items
          Icons.inventory_2,
          isCurrency: false,
        ),
        const SizedBox(height: AppSizes.spacing24),
        
        // Tabla de comparación de productos
        if (productComparisons.isNotEmpty)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(AppSizes.spacing16),
                  child: Text(
                    'Top 10 Productos - Comparación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Ventas Actuales')),
                      DataColumn(label: Text('Cant. Actual')),
                      DataColumn(label: Text('Ventas Anteriores')),
                      DataColumn(label: Text('Cant. Anterior')),
                      DataColumn(label: Text('Crecimiento')),
                    ],
                    rows: productComparisons.take(10).map<DataRow>((product) {
                      final growth = product['growth'] ?? 0;
                      final growthColor = growth > 0 ? Colors.green : growth < 0 ? Colors.red : Colors.grey;
                      
                      return DataRow(cells: [
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              product['productName'] ?? 'Sin nombre',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(_formatCurrency((product['currentSales'] ?? 0) as num))),
                        DataCell(Text('${product['currentQuantity'] ?? 0}')),
                        DataCell(Text(_formatCurrency((product['previousSales'] ?? 0) as num))),
                        DataCell(Text('${product['previousQuantity'] ?? 0}')),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                growth > 0 ? Icons.arrow_upward : growth < 0 ? Icons.arrow_downward : Icons.remove,
                                color: growthColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${growth.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: growthColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    String title,
    dynamic currentValue,
    dynamic previousValue,
    double growth,
    IconData icon, {
    bool isCurrency = true,
  }) {
    final isPositive = growth >= 0;
    final growthColor = isPositive ? Colors.green : Colors.red;
    final growthIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    String formatValue(dynamic value) {
      if (value is num) {
        if (isCurrency) {
          return _formatCurrency(value);
        } else {
          return value.toStringAsFixed(value is double && value % 1 != 0 ? 2 : 0);
        }
      }
      return value.toString();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  Row(
                    children: [
                      Text(
                        'Actual: ${formatValue(currentValue)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: AppSizes.spacing16),
                      Text(
                        'Anterior: ${formatValue(previousValue)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: growthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(growthIcon, color: growthColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: growthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
