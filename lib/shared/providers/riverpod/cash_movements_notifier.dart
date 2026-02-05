import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/cash_register.dart';
import 'package:bellezapp_web/shared/providers/cash_register_api.dart';

// State class
class CashMovementsState {
  final List<CashMovement> movements;
  final bool isLoading;
  final String? error;
  final String? typeFilter; // 'venta_qr', 'venta_efectivo', 'entrada', 'salida', null for all
  final DateTime? selectedDate;

  const CashMovementsState({
    this.movements = const [],
    this.isLoading = false,
    this.error,
    this.typeFilter,
    this.selectedDate,
  });

  CashMovementsState copyWith({
    List<CashMovement>? movements,
    bool? isLoading,
    String? error,
    String? typeFilter,
    DateTime? selectedDate,
  }) {
    return CashMovementsState(
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  // Convenience getters
  List<CashMovement> get filteredMovements {
    if (typeFilter == null) return movements;
    return movements.where((m) => m.type == typeFilter).toList();
  }

  double get totalIncomeAmount => filteredMovements
      .where((m) => m.isIncome)
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get totalOutcomeAmount => filteredMovements
      .where((m) => m.isOutcome)
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get netAmount => totalIncomeAmount - totalOutcomeAmount;

  int get totalCount => filteredMovements.length;
}

// Notifier
class CashMovementsNotifier extends StateNotifier<CashMovementsState> {
  final CashRegisterApi cashRegisterApi;
  final String? cashRegisterId;

  CashMovementsNotifier({
    required this.cashRegisterApi,
    required this.cashRegisterId,
  }) : super(const CashMovementsState());

  Future<void> loadMovements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movements = await cashRegisterApi.getCashMovements(
        cashRegisterId: cashRegisterId,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        movements: movements,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMovementsByDate(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movements = await cashRegisterApi.getCashMovements(
        cashRegisterId: cashRegisterId,
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      );

      state = state.copyWith(
        movements: movements,
        isLoading: false,
        selectedDate: date,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type);
  }

  Future<void> refreshMovements() async {
    if (state.selectedDate != null) {
      await loadMovementsByDate(state.selectedDate!);
    } else {
      await loadMovements();
    }
  }

  // Summary calculation for cash closing
  Map<String, double> getSummary() {
    return {
      'qr_sales': state.movements
          .where((m) => m.type == 'venta_qr')
          .fold<double>(0, (sum, m) => sum + m.amount),
      'cash_sales': state.movements
          .where((m) => m.type == 'venta_efectivo')
          .fold<double>(0, (sum, m) => sum + m.amount),
      'total_income': state.totalIncomeAmount,
      'total_outcome': state.totalOutcomeAmount,
      'net_amount': state.netAmount,
    };
  }
}

// Provider
final cashMovementsProvider = StateNotifierProvider.family<
    CashMovementsNotifier,
    CashMovementsState,
    (String?, DateTime?)>((ref, params) {
  final (cashRegisterId, openingTime) = params;
  final cashRegisterApi = ref.watch(cashRegisterApiProvider);
  
  final notifier = CashMovementsNotifier(
    cashRegisterApi: cashRegisterApi,
    cashRegisterId: cashRegisterId,
  );

  // Auto-load movements from opening time until now
  Future.microtask(() async {
    if (openingTime != null) {
      await notifier.loadMovements(
        startDate: openingTime,
        endDate: DateTime.now(),
      );
    } else {
      await notifier.loadMovements();
    }
  });

  return notifier;
});
