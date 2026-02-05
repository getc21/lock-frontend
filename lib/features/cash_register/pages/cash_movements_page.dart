import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bellezapp_web/shared/providers/riverpod/cash_movements_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/cash_register_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/cash_movement_row_widget.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';

class CashMovementsPage extends ConsumerStatefulWidget {
  const CashMovementsPage({super.key});

  @override
  ConsumerState<CashMovementsPage> createState() => _CashMovementsPageState();
}

class _CashMovementsPageState extends ConsumerState<CashMovementsPage> {
  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeId = storeState.currentStore?['_id'] ?? storeState.currentStore?['id'] ?? 'default';
    final cashRegisterState = ref.watch(cashRegisterProvider(storeId));
    final movementsState = ref.watch(
      cashMovementsProvider((
        cashRegisterState.currentCashRegister?.id,
        cashRegisterState.currentCashRegister?.openingTime,
      )),
    );

    return DashboardLayout(
      title: 'Movimientos de Caja',
      currentRoute: '/cash-movements',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/cash-register'),
                  ),
                  Text(
                    'Movimientos de Caja',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref
                      .read(
                          cashMovementsProvider((
                            cashRegisterState.currentCashRegister?.id,
                            cashRegisterState.currentCashRegister?.openingTime,
                          ))
                          .notifier)
                      .refreshMovements();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Content
          if (movementsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (movementsState.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${movementsState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(
                              cashMovementsProvider((
                                cashRegisterState.currentCashRegister?.id,
                                cashRegisterState.currentCashRegister?.openingTime,
                              ))
                              .notifier)
                          .refreshMovements();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Summary section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCard(
                              context,
                              'Ingresos',
                              movementsState.totalIncomeAmount,
                              Colors.green,
                            ),
                            _buildSummaryCard(
                              context,
                              'Egresos',
                              movementsState.totalOutcomeAmount,
                              Colors.red,
                            ),
                            _buildSummaryCard(
                              context,
                              'En Caja',
                              (cashRegisterState.currentCashRegister?.openingAmount ?? 0) + 
                              (movementsState.totalIncomeAmount - movementsState.totalOutcomeAmount) +
                              cashRegisterState.totalSalesAmount,
                              Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total de movimientos: ${movementsState.filteredMovements.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Movements list
                if (movementsState.filteredMovements.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay movimientos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: movementsState.filteredMovements.map((movement) {
                        return CashMovementRowWidget(movement: movement);
                      }).toList(),
                    ),
                  ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Bs. ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
