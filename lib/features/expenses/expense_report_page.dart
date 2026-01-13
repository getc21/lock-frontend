import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/expense_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';
import '../../shared/widgets/loading_indicator.dart';

// Re-export las clases que ya existen en expense_notifier
export '../../shared/providers/riverpod/expense_notifier.dart'
    show ExpenseReport, ExpenseCategory, ExpenseItem;
class ExpenseReportPage extends ConsumerStatefulWidget {
  const ExpenseReportPage({super.key});

  @override
  ConsumerState<ExpenseReportPage> createState() => _ExpenseReportPageState();
}

class _ExpenseReportPageState extends ConsumerState<ExpenseReportPage> {
  String _selectedPeriod = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDateRange = false;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    
    // Cargar reporte inicial después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isEmployee && !authState.isManager && !authState.isAdmin) {
        // Para empleados, cargar solo gastos del día actual
        final store = ref.read(storeProvider).currentStore;
        if (store != null) {
          ref.read(expenseProvider.notifier).loadExpenses(store['_id']);
        }
      } else {
        // Para admin/gerente, cargar reporte
        _loadReport();
      }
    });
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'monthly':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  Future<void> _loadReport() async {
    final store = ref.read(storeProvider).currentStore;
    if (store == null) {
      print('🔴 [ExpenseReport] No hay tienda seleccionada');
      return;
    }

    final storeId = store['_id'] as String?;
    final storeName = store['name'] as String? ?? 'Sin nombre';
    
    if (storeId == null) {
      print('🔴 [ExpenseReport] storeId es nulo');
      return;
    }

    print('🟡 [ExpenseReport] Cargando reporte para tienda: $storeName ($storeId)');

    final expenseNotifier = ref.read(expenseProvider.notifier);

    if (_isCustomDateRange && _startDate != null && _endDate != null) {
      // Ajustar fechas para incluir todo el día final
      final startDate = _startDate!;
      final endDate = _endDate!.add(Duration(hours: 23, minutes: 59, seconds: 59));
      
      print('📊 [ExpenseReport] Rango personalizado: ${startDate.toString()} a ${endDate.toString()}');
      
      await expenseNotifier.loadExpenseReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      print('📊 [ExpenseReport] Período: $_selectedPeriod');
      
      await expenseNotifier.loadExpenseReport(
        storeId: storeId,
        period: _selectedPeriod,
      );
    }
    
    print('✅ [ExpenseReport] Reporte cargado exitosamente');
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isCustomDateRange = true;
        _selectedPeriod = 'custom';
      });
      
      // Usar WidgetsBinding para evitar problemas con setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReport();
      });
    }
  }

  Future<void> _generateExpensePDF() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    final startDatePicker = await showDatePicker(
      context: context,
      initialDate: firstDayOfMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDatePicker == null) return;

    final endDatePicker = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: startDatePicker,
      lastDate: DateTime.now(),
    );

    if (endDatePicker == null) return;

    final store = ref.read(storeProvider).currentStore;
    if (store == null) return;
    
    final expenseNotifier = ref.read(expenseProvider.notifier);

    // Cargar gastos para el rango de fechas
    await expenseNotifier.loadExpenseReport(
      storeId: store['_id'],
      startDate: startDatePicker,
      endDate: endDatePicker.add(Duration(hours: 23, minutes: 59, seconds: 59)),
    );

    final expenseState = ref.read(expenseProvider);
    final report = expenseState.report;

    if (report != null) {
      _createAndPrintPDF(report, startDatePicker, endDatePicker, store);
    }
  }

  Future<void> _createAndPrintPDF(
    ExpenseReport report,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic>? store,
  ) async {
    final pdf = pw.Document();
    final currencyNotifier = ref.read(currencyProvider.notifier);

    // Usar fuentes que soporten Unicode
    final ttfFont = await PdfGoogleFonts.robotoRegular();
    final ttfFontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REPORTE DE GASTOS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: ttfFontBold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                store?['name'] ?? 'Tienda',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                  font: ttfFont,
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Divider(),
              ),
            ],
          ),

          // Rango de fechas
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Período:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: ttfFontBold,
                    ),
                  ),
                  pw.Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: pw.TextStyle(font: ttfFont),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Fecha de Generación:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      font: ttfFontBold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(font: ttfFont),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Resumen
          pw.Container(
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESUMEN',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    font: ttfFontBold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Gastos:',
                          style: pw.TextStyle(font: ttfFont),
                        ),
                        pw.Text(
                          '${currencyNotifier.symbol}${report.totalExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            font: ttfFontBold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Número de Transacciones:',
                          style: pw.TextStyle(font: ttfFont),
                        ),
                        pw.Text(
                          '${report.expenseCount}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            font: ttfFontBold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Promedio por Gasto:',
                          style: pw.TextStyle(font: ttfFont),
                        ),
                        pw.Text(
                          '${currencyNotifier.symbol}${report.averageExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            font: ttfFontBold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Desglose por categoría
          pw.Text(
            'DESGLOSE POR CATEGORÍA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              font: ttfFontBold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Categoría', 'Total', 'Transacciones', 'Porcentaje'],
            data: report.byCategory
                .map((cat) => [
                  cat.name,
                  '${currencyNotifier.symbol}${cat.total.toStringAsFixed(2)}',
                  '${cat.count}',
                  '${(cat.total / report.totalExpense * 100).toStringAsFixed(1)}%',
                ])
                .toList(),
            cellHeight: 30,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: ttfFontBold,
            ),
            cellStyle: pw.TextStyle(font: ttfFont),
          ),
          pw.SizedBox(height: 24),

          // Top 10 gastos
          pw.Text(
            'PRINCIPALES GASTOS',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              font: ttfFontBold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Descripción', 'Monto'],
            data: report.topExpenses
                .take(10)
                .map((exp) => [
                  DateFormat('dd/MM/yyyy').format(exp.date),
                  exp.description ?? 'Sin descripción',
                  '${currencyNotifier.symbol}${exp.amount.toStringAsFixed(2)}',
                ])
                .toList(),
            cellHeight: 30,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: ttfFontBold,
            ),
            cellStyle: pw.TextStyle(font: ttfFont),
          ),
          pw.SizedBox(height: 40),

          // Pie de página
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Documento generado automáticamente por Bellezapp',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                font: ttfFont,
              ),
            ),
          ),
        ],
      ),
    );

    // Generar y mostrar el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Gastos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // Vista para empleados
  Widget _buildEmployeeView(BuildContext context, ExpenseState expenseState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Gastos de Hoy',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spacing24),
          
          // Botón registrar gasto
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/expenses/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar Nuevo Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacing12),
              ),
            ),
          ),
          SizedBox(height: AppSizes.spacing24),
          
          // Mostrar gastos del día
          if (expenseState.isLoading)
            LoadingIndicator(
              message: 'Cargando gastos...',
              color: Theme.of(context).primaryColor,
            )
          else if (expenseState.error != null)
            Container(
              padding: EdgeInsets.all(AppSizes.spacing24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                expenseState.error!,
                style: TextStyle(color: AppColors.error),
              ),
            )
          else if (expenseState.expenses.isNotEmpty)
            Card(
              elevation: 0,
              color: AppColors.surface,
              child: Padding(
                padding: EdgeInsets.all(AppSizes.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos Registrados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacing12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: expenseState.expenses.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final expense = expenseState.expenses[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.spacing12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense['description'] ?? 'Sin descripción',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      expense['categoryId'] != null ? 'Categoría' : 'Sin categoría',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(expense['amount'] as num).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                  SizedBox(height: AppSizes.spacing12),
                  Text(
                    'No hay gastos registrados hoy',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Vista para admin y gerente
  Widget _buildAdminManagerView(
    BuildContext context,
    ExpenseState expenseState,
    ExpenseReport? report,
  ) {
    return expenseState.isLoading
        ? LoadingIndicator(
            message: 'Cargando reporte...',
            color: Theme.of(context).primaryColor,
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FILTROS
                _buildFilterSection(),
                SizedBox(height: AppSizes.spacing12),

                // BOTÓN REGISTRAR GASTO
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _generateExpensePDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generar PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(width: AppSizes.spacing12),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/expenses/new');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar Gasto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.spacing12),

                if (expenseState.error != null)
                  Container(
                    padding: EdgeInsets.all(AppSizes.spacing24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      expenseState.error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  )
                else if (report != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // RESUMEN GENERAL
                      _buildSummaryCards(report),
                      SizedBox(height: AppSizes.spacing12),

                      // GASTOS POR CATEGORÍA
                      _buildCategoryBreakdown(report),
                      SizedBox(height: AppSizes.spacing12),
                      // TOP GASTOS
                      _buildTopExpenses(report),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      'No hay datos disponibles',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final authState = ref.watch(authProvider);
    final storeState = ref.watch(storeProvider);  // 🔴 Observar cambios de tienda
    final isEmployeeOnly = authState.isEmployee && !authState.isManager && !authState.isAdmin;
    final report = expenseState.report;

    // 🔴 EFECTO: Recargar reporte cuando cambia la tienda
    // Este listener se ejecuta cada vez que storeProvider cambia
    ref.listen<StoreState>(storeProvider, (previous, next) {
      if (previous != null && next != null) {
        final prevStoreId = previous.currentStore?['_id'];
        final nextStoreId = next.currentStore?['_id'];
        
        if (prevStoreId != null && 
            nextStoreId != null && 
            prevStoreId != nextStoreId) {
          print('🔴 [ExpenseReport-BUILD] Tienda cambió de $prevStoreId a $nextStoreId');
          _loadReport();
        }
      }
    });

    return DashboardLayout(
      title: 'Reportes de Gastos',
      currentRoute: '/expenses/report',
      child: isEmployeeOnly
          ? _buildEmployeeView(context, expenseState)
          : _buildAdminManagerView(context, expenseState, report),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar por período',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSizes.spacing12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodButton('Hoy', 'daily'),
                  SizedBox(width: AppSizes.spacing12),
                  _buildPeriodButton('Semana', 'weekly'),
                  SizedBox(width: AppSizes.spacing12),
                  _buildPeriodButton('Mes', 'monthly'),
                  SizedBox(width: AppSizes.spacing12),
                  _buildPeriodButton('Año', 'yearly'),
                  SizedBox(width: AppSizes.spacing12),
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Personalizado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_isCustomDateRange && _startDate != null && _endDate != null)
              Padding(
                padding: EdgeInsets.only(top: AppSizes.spacing12),
                child: Text(
                  'Del ${DateFormat('dd/MM/yyyy').format(_startDate!)} al ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period && !_isCustomDateRange;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
          _isCustomDateRange = false;
          _setDefaultDates();
        });
        // Usar WidgetsBinding para evitar problemas con setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadReport();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : AppColors.border,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildSummaryCards(ExpenseReport report) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Gastos',
            _formatCurrency(report.totalExpense),
            '${report.expenseCount} transacciones',
            Icons.trending_down,
            AppColors.error,
          ),
        ),
        SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: _buildMetricCard(
            'Promedio',
            _formatCurrency(report.averageExpense),
            'Por gasto',
            Icons.calculate,
            AppColors.warning,
          ),
        ),
        SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: _buildMetricCard(
            'Categorías',
            '${report.byCategory.length}',
            'Tipos de gastos',
            Icons.category,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            SizedBox(height: AppSizes.spacing12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            SizedBox(height: AppSizes.spacing12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ExpenseReport report) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por Categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSizes.spacing12),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: report.byCategory.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final category = report.byCategory[index];
                final percentage = (category.total / report.totalExpense * 100);

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (category.icon != null)
                                  Icon(Icons.category, size: 20)
                                else
                                  Icon(Icons.receipt, size: 20),
                                SizedBox(width: AppSizes.spacing12),
                                Expanded(
                                  child: Text(category.name),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(category.total),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.spacing12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSizes.spacing12),
                      Text(
                        '${category.count} transacciones',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExpenses(ExpenseReport report) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Principales Gastos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSizes.spacing12),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: report.topExpenses.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final expense = report.topExpenses[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.spacing12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description ?? 'Sin descripción',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(expense.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(expense.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
