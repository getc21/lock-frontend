import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bellezapp_web/shared/providers/riverpod/cash_register_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/cash_movements_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';
import 'package:intl/intl.dart';

class CashRegisterPage extends ConsumerStatefulWidget {
  const CashRegisterPage({super.key});

  @override
  ConsumerState<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends ConsumerState<CashRegisterPage> {
  late TextEditingController _openingAmountController;
  late TextEditingController _closingAmountController;
  late TextEditingController _incomeAmountController;
  late TextEditingController _incomeDescriptionController;
  late TextEditingController _outcomeAmountController;

  @override
  void initState() {
    super.initState();
    _openingAmountController = TextEditingController();
    _closingAmountController = TextEditingController();
    _incomeAmountController = TextEditingController();
    _incomeDescriptionController = TextEditingController();
    _outcomeAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _openingAmountController.dispose();
    _closingAmountController.dispose();
    _incomeAmountController.dispose();
    _incomeDescriptionController.dispose();
    _outcomeAmountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeId = storeState.currentStore?['_id'] ?? storeState.currentStore?['id'] ?? 'default';
    final cashRegisterState = ref.watch(cashRegisterProvider(storeId));

    return DashboardLayout(
      title: 'Sistema de Caja',
      currentRoute: '/cash-register',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sistema de Caja',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref
                          .read(cashRegisterProvider(storeId ?? 'default').notifier)
                          .refreshCashRegister();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => context.go('/cash-movements'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (cashRegisterState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (cashRegisterState.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${cashRegisterState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(cashRegisterProvider(storeId ?? 'default').notifier)
                          .refreshCashRegister();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCashStatusCard(context, cashRegisterState),
                    const SizedBox(height: 24),
                    if (cashRegisterState.isOpen)
                      _buildDailySummaryCard(context, cashRegisterState),
                    if (cashRegisterState.isOpen)
                      const SizedBox(height: 24),
                    _buildMainActionsCard(context, storeId, cashRegisterState),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCashStatusCard(BuildContext context, CashRegisterState state) {
    final isOpen = state.isOpen;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOpen ? Icons.lock_open : Icons.lock,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Caja',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      isOpen ? 'ABIERTA' : 'CERRADA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de apertura',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentCashRegister != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(state.currentCashRegister!.openingTime)
                            : 'N/A',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monto inicial',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentCashRegister != null
                            ? _formatCurrency(state.currentCashRegister!.openingAmount)
                            : _formatCurrency(0.0),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(BuildContext context, CashRegisterState state) {
    final openingAmount = state.currentCashRegister?.openingAmount ?? 0.0;
    final totalSales = state.totalSalesAmount;
    final totalCashSales = state.totalCashSalesAmount;
    final totalQRSales = state.totalQRSalesAmount;
    final totalIncome = state.totalIncomeAmount; // Entradas + Ventas
    final totalExpense = state.totalOutcomeAmount; // Salidas
    final neto = totalIncome - totalExpense;
    final currentInCash = openingAmount + neto + totalSales;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen desde Apertura', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildSummaryRow(context, 'Monto de apertura:', openingAmount, Colors.grey),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Total Ventas:', totalSales, Colors.blue),
            const SizedBox(height: 8),
            if (totalCashSales > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildSummaryRow(context, '  En efectivo:', totalCashSales, Colors.blue, isSubtotal: true),
              ),
            if (totalQRSales > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildSummaryRow(context, '  Por QR/Tarjeta:', totalQRSales, Colors.cyan, isSubtotal: true),
              ),
            ],
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Entradas:', totalIncome, Colors.green),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Salidas:', totalExpense, Colors.red),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Neto (Ingresos - Egresos):', neto, Colors.orange, isTotal: true),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'TOTAL EN CAJA:', currentInCash, Colors.blue, isTotal: true),
            const SizedBox(height: 16),
            Text(
              'Total de movimientos: ${state.totalIncome + state.totalOutcome}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double amount, Color? color, {bool isTotal = false, bool isSubtotal = false, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : null,
                fontSize: isSubtotal ? 13 : null,
              ),
            ),
            Text(
              _formatCurrency(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : null,
                color: color,
                fontSize: isTotal ? 18 : (isSubtotal ? 13 : null),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainActionsCard(BuildContext context, String? storeId, CashRegisterState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            if (!state.isOpen)
              _buildActionButton(context, 'Abrir Caja', 'Iniciar jornada con monto inicial', Icons.lock_open,
                  Colors.green, () => _showOpenCashDialog(context, storeId))
            else
              Column(
                children: [
                  _buildActionButton(context, 'Cerrar Caja', 'Realizar arqueo y cerrar jornada', Icons.lock,
                      Colors.orange, () => _showCloseCashDialog(context, storeId)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryActionButton(context, 'Entrada', Icons.add_circle, Colors.teal,
                            () => _showAddIncomeDialog(context, storeId, ref)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryActionButton(context, 'Salida', Icons.remove_circle, Colors.red,
                            () => _showAddOutcomeDialog(context, storeId, ref)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(context, 'Ver Movimientos', 'Gestionar entradas y salidas', Icons.receipt_long,
                      Theme.of(context).primaryColor, () => context.go('/cash-movements')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, String subtitle, IconData icon, Color color,
      VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton(BuildContext context, String label, IconData icon, Color color,
      VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showOpenCashDialog(BuildContext context, String? storeId) {
    _openingAmountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el monto inicial para abrir la caja'),
            const SizedBox(height: 16),
            TextField(
              controller: _openingAmountController,
              decoration: InputDecoration(
                labelText: 'Monto de apertura',
                hintText: '0.00',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_openingAmountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
                return;
              }
              ref.read(cashRegisterProvider(storeId ?? 'default').notifier).openCash(amount);
              Navigator.pop(context);
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  void _showCloseCashDialog(BuildContext context, String? storeId) {
    _closingAmountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el monto final para cerrar la caja'),
            const SizedBox(height: 16),
            TextField(
              controller: _closingAmountController,
              decoration: InputDecoration(
                labelText: 'Monto de cierre',
                hintText: '0.00',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_closingAmountController.text) ?? 0;
              if (amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
                return;
              }
              ref.read(cashRegisterProvider(storeId ?? 'default').notifier).closeCash(amount);
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, String? storeId, WidgetRef ref) {
    _incomeAmountController.clear();
    _incomeDescriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Entrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _incomeDescriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeAmountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_incomeAmountController.text) ?? 0;
              final description = _incomeDescriptionController.text;
              
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
                return;
              }
              
              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese una descripción')));
                return;
              }

              // Get current cash register ID
              final cashRegisterState = ref.read(cashRegisterProvider(storeId ?? 'default'));
              final cashRegisterId = cashRegisterState.currentCashRegister?.id;

              if (cashRegisterId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No hay caja abierta')));
                return;
              }

              // Add income movement
              if (mounted) {
                Navigator.pop(context);
              }
              
              await ref
                  .read(cashRegisterProvider(storeId ?? 'default').notifier)
                  .addIncome(
                    cashRegisterId: cashRegisterId,
                    amount: amount,
                    description: description,
                    storeId: storeId ?? 'default',
                  );
              
              // Refresh the lists
              ref
                  .read(cashRegisterProvider(storeId ?? 'default').notifier)
                  .refreshCashRegister();
              
              ref
                  .read(cashMovementsProvider((
                    cashRegisterState.currentCashRegister?.id,
                    cashRegisterState.currentCashRegister?.openingTime,
                  )).notifier)
                  .refreshMovements();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddOutcomeDialog(BuildContext context, String? storeId, WidgetRef ref) {
    _outcomeAmountController.clear();
    _incomeDescriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Salida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _incomeDescriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _outcomeAmountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_outcomeAmountController.text) ?? 0;
              final description = _incomeDescriptionController.text;
              
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
                return;
              }
              
              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese una descripción')));
                return;
              }

              // Get current cash register ID
              final cashRegisterState = ref.read(cashRegisterProvider(storeId ?? 'default'));
              final cashRegisterId = cashRegisterState.currentCashRegister?.id;

              if (cashRegisterId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No hay caja abierta')));
                return;
              }

              // Add outcome movement
              if (mounted) {
                Navigator.pop(context);
              }
              
              await ref
                  .read(cashRegisterProvider(storeId ?? 'default').notifier)
                  .addOutcome(
                    cashRegisterId: cashRegisterId,
                    amount: amount,
                    description: description,
                    storeId: storeId ?? 'default',
                  );
              
              // Refresh the lists
              ref
                  .read(cashRegisterProvider(storeId ?? 'default').notifier)
                  .refreshCashRegister();
              
              ref
                  .read(cashMovementsProvider((
                    cashRegisterState.currentCashRegister?.id,
                    cashRegisterState.currentCashRegister?.openingTime,
                  )).notifier)
                  .refreshMovements();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
