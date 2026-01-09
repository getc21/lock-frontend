import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../providers/riverpod/expense_notifier.dart';
import '../providers/riverpod/store_notifier.dart';
import '../providers/riverpod/currency_notifier.dart';

class ExpensesWidget extends ConsumerStatefulWidget {
  const ExpensesWidget({super.key});

  @override
  ConsumerState<ExpensesWidget> createState() => _ExpensesWidgetState();
}

class _ExpensesWidgetState extends ConsumerState<ExpensesWidget> {
  @override
  void initState() {
    super.initState();
    _loadTodayExpenses();
  }

  void _loadTodayExpenses() {
    final store = ref.read(storeProvider).currentStore;
    if (store != null) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      Future.microtask(() async {
        await ref.read(expenseProvider.notifier).loadExpenseReport(
              storeId: store['_id'],
              startDate: startOfDay,
              endDate: endOfDay,
            );
      });
    }
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final report = expenseState.report;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: AppColors.error, size: 24),
                    SizedBox(width: AppSizes.spacing12),
                    Text(
                      'Gastos de Hoy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.push('/expenses/report');
                  },
                  child: Text('Ver todos →'),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacing12),

            if (expenseState.isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacing12),
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (report != null && report.expenseCount > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RESUMEN
                  Container(
                    padding: EdgeInsets.all(AppSizes.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Gastos',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatCurrency(report.totalExpense),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${report.expenseCount} transacciones',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Promedio: ${_formatCurrency(report.averageExpense)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spacing12),

                  // CATEGORÍAS
                  if (report.byCategory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Por Categoría',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        SizedBox(height: AppSizes.spacing12),
                        ...report.byCategory.take(3).map((category) {
                          final percentage =
                              (category.total / report.totalExpense * 100);
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: AppSizes.spacing12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(category.total),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: AppSizes.spacing12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (report.byCategory.length > 3)
                          Padding(
                            padding: EdgeInsets.only(
                                top: AppSizes.spacing12),
                            child: Text(
                              '+${report.byCategory.length - 3} categorías más',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),

                  SizedBox(height: AppSizes.spacing12),

                  // BOTÓN
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
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppSizes.spacing12),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 40),
                      SizedBox(height: AppSizes.spacing12),
                      Text(
                        'Sin gastos registrados hoy',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: AppSizes.spacing12),
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
              ),
          ],
        ),
      ),
    );
  }
}
