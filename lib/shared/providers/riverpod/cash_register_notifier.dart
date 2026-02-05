import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/cash_register.dart';
import 'package:bellezapp_web/shared/providers/cash_register_api.dart';

// State class
class CashRegisterState {
  final CashRegister? currentCashRegister;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<CashMovement> dailyMovements;
  final bool isRegistered;

  const CashRegisterState({
    this.currentCashRegister,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.dailyMovements = const [],
    this.isRegistered = false,
  });

  CashRegisterState copyWith({
    CashRegister? currentCashRegister,
    bool? isLoading,
    String? error,
    String? successMessage,
    List<CashMovement>? dailyMovements,
    bool? isRegistered,
  }) {
    return CashRegisterState(
      currentCashRegister: currentCashRegister ?? this.currentCashRegister,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      dailyMovements: dailyMovements ?? this.dailyMovements,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  // Convenience getters
  bool get isOpen => currentCashRegister != null && 
      currentCashRegister!.status == 'open';
  
  double get expectedAmount {
    if (!isOpen || currentCashRegister == null) return 0;
    
    // expectedAmount = openingAmount + totalSales + totalIncome - totalExpense
    final openingAmount = currentCashRegister!.openingAmount;
    final totalSales = totalSalesAmount;
    final totalIncome = totalIncomeAmount;
    final totalExpense = totalOutcomeAmount;
    
    return openingAmount + totalSales + totalIncome - totalExpense;
  }

  double get variance {
    if (!isOpen || currentCashRegister == null) return 0;
    return (currentCashRegister!.expectedAmount ?? 0) - expectedAmount;
  }

  int get totalIncome => dailyMovements
      .where((m) => m.isIncome)
      .length;

  int get totalOutcome => dailyMovements
      .where((m) => m.isOutcome)
      .length;

  double get totalIncomeAmount => dailyMovements
      .where((m) => m.isIncome)
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get totalOutcomeAmount => dailyMovements
      .where((m) => m.isOutcome)
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get totalSalesAmount => dailyMovements
      .where((m) => m.type == 'venta' || m.type == 'sale')
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get totalCashSalesAmount => dailyMovements
      .where((m) => (m.type == 'venta' || m.type == 'sale') && m.paymentMethod == 'efectivo')
      .fold<double>(0, (sum, m) => sum + m.amount);

  double get totalQRSalesAmount => dailyMovements
      .where((m) => (m.type == 'venta' || m.type == 'sale') && (m.paymentMethod == 'qr' || m.paymentMethod == 'tarjeta'))
      .fold<double>(0, (sum, m) => sum + m.amount);
}

// Notifier
class CashRegisterNotifier extends StateNotifier<CashRegisterState> {
  final CashRegisterApi cashRegisterApi;
  final String storeId;

  CashRegisterNotifier({
    required this.cashRegisterApi,
    required this.storeId,
  }) : super(const CashRegisterState());

  Future<void> loadCurrentCashRegister() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cashRegister = 
          await cashRegisterApi.getCurrentCashRegister(storeId);
      
      state = state.copyWith(
        currentCashRegister: cashRegister,
        isLoading: false,
        isRegistered: cashRegister != null,
      );

      if (cashRegister != null) {
        await loadDailyMovements();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadDailyMovements() async {
    if (state.currentCashRegister == null) return;

    try {
      final movements = await cashRegisterApi.getCashMovements(
        cashRegisterId: state.currentCashRegister!.id,
        startDate: state.currentCashRegister!.openingTime,
        endDate: DateTime.now(),
      );

      state = state.copyWith(dailyMovements: movements);
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar movimientos: ${e.toString()}');
    }
  }

  Future<void> openCash(double openingAmount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cashRegister = await cashRegisterApi.openCashRegister(
        storeId: storeId,
        openingAmount: openingAmount,
      );

      state = state.copyWith(
        currentCashRegister: cashRegister,
        isLoading: false,
        isRegistered: true,
        successMessage: 'Caja abierta exitosamente',
        dailyMovements: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo abrir la caja: ${e.toString()}',
      );
    }
  }

  Future<void> closeCash(double closingAmount) async {
    if (state.currentCashRegister == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final cashRegister = await cashRegisterApi.closeCashRegister(
        cashRegisterId: state.currentCashRegister!.id ?? 'unknown',
        closingAmount: closingAmount,
      );

      state = state.copyWith(
        currentCashRegister: cashRegister,
        isLoading: false,
        isRegistered: false,
        successMessage: 'Caja cerrada exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo cerrar la caja: ${e.toString()}',
      );
    }
  }

  Future<void> addMovement({
    required String type,
    required double amount,
    required String description,
  }) async {
    if (state.currentCashRegister == null) return;

    try {
      final movement = await cashRegisterApi.addCashMovement(
        cashRegisterId: state.currentCashRegister!.id ?? 'unknown',
        type: type,
        amount: amount,
        description: description,
        storeId: storeId,
      );

      final updatedMovements = [...state.dailyMovements, movement];
      state = state.copyWith(dailyMovements: updatedMovements);
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo agregar el movimiento: ${e.toString()}',
      );
    }
  }

  Future<void> addIncome({
    required String cashRegisterId,
    required double amount,
    required String description,
    required String storeId,
  }) async {
    try {
      final movement = await cashRegisterApi.addCashMovement(
        cashRegisterId: cashRegisterId,
        type: 'entrada',
        amount: amount,
        description: description,
        storeId: storeId,
      );

      final updatedMovements = [...state.dailyMovements, movement];
      state = state.copyWith(dailyMovements: updatedMovements);
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo agregar la entrada: ${e.toString()}',
      );
    }
  }

  Future<void> addOutcome({
    required String cashRegisterId,
    required double amount,
    required String description,
    required String storeId,
  }) async {
    try {
      final movement = await cashRegisterApi.addCashMovement(
        cashRegisterId: cashRegisterId,
        type: 'salida',
        amount: amount,
        description: description,
        storeId: storeId,
      );

      final updatedMovements = [...state.dailyMovements, movement];
      state = state.copyWith(dailyMovements: updatedMovements);
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo agregar la salida: ${e.toString()}',
      );
    }
  }

  Future<void> refreshCashRegister() async {
    await loadCurrentCashRegister();
  }
}

// Provider
final cashRegisterProvider =
    StateNotifierProvider.family<CashRegisterNotifier, CashRegisterState, String>(
  (ref, storeId) {
    final cashRegisterApi = ref.watch(cashRegisterApiProvider);
    
    final notifier = CashRegisterNotifier(
      cashRegisterApi: cashRegisterApi,
      storeId: storeId,
    );

    // Auto-load on first creation
    Future.microtask(() async {
      await notifier.loadCurrentCashRegister();
    });

    return notifier;
  },
);
