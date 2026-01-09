import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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
    // Cargar reporte después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar si es empleado para cargar solo hoy
      final authState = ref.read(authProvider);
      if (authState.isEmployee && !authState.isManager && !authState.isAdmin) {
        // Para empleados, cargar solo gastos del día actual
        final store = ref.read(storeProvider).currentStore;
        if (store != null) {
          final today = DateTime.now();
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
    if (store == null) return;

    final expenseNotifier = ref.read(expenseProvider.notifier);

    if (_isCustomDateRange && _startDate != null && _endDate != null) {
      // Ajustar fechas para incluir todo el día final
      final startDate = _startDate!;
      final endDate = _endDate!.add(Duration(hours: 23, minutes: 59, seconds: 59));
      
      await expenseNotifier.loadExpenseReport(
        storeId: store['_id'],
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      await expenseNotifier.loadExpenseReport(
        storeId: store['_id'],
        period: _selectedPeriod,
      );
    }
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
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/expenses/new');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Gasto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
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
    final isEmployeeOnly = authState.isEmployee && !authState.isManager && !authState.isAdmin;
    final report = expenseState.report;

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
