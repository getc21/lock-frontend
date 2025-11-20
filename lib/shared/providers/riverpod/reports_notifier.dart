import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../reports_provider.dart' as reports_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';

class ReportsState {
  final Map<String, dynamic> inventoryRotation;
  final Map<String, dynamic> profitability;
  final Map<String, dynamic> salesTrends;
  final Map<String, dynamic> periodsComparison;
  final bool isLoading;
  final String errorMessage;

  ReportsState({
    this.inventoryRotation = const {},
    this.profitability = const {},
    this.salesTrends = const {},
    this.periodsComparison = const {},
    this.isLoading = false,
    this.errorMessage = '',
  });

  ReportsState copyWith({
    Map<String, dynamic>? inventoryRotation,
    Map<String, dynamic>? profitability,
    Map<String, dynamic>? salesTrends,
    Map<String, dynamic>? periodsComparison,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReportsState(
      inventoryRotation: inventoryRotation ?? this.inventoryRotation,
      profitability: profitability ?? this.profitability,
      salesTrends: salesTrends ?? this.salesTrends,
      periodsComparison: periodsComparison ?? this.periodsComparison,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref ref;

  ReportsNotifier(this.ref) : super(ReportsState());

  late reports_api.ReportsProvider _reportsProvider;

  void _initReportsProvider() {
    final authState = ref.read(authProvider);
    _reportsProvider = reports_api.ReportsProvider(authState.token);
  }

  Future<bool> loadInventoryRotationAnalysis({
    required String startDate,
    required String endDate,
    String period = 'monthly',
  }) async {
    _initReportsProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final storeState = ref.read(storeProvider);
      if (storeState.currentStore == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No store selected',
        );
        return false;
      }

      final result = await _reportsProvider.getInventoryRotationAnalysis(
        storeId: storeState.currentStore!['_id'],
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      if (result['success']) {
        state = state.copyWith(
          inventoryRotation: result['data'] ?? {},
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error cargando análisis de rotación',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  Future<bool> loadProfitabilityAnalysis({
    required String startDate,
    required String endDate,
  }) async {
    _initReportsProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final storeState = ref.read(storeProvider);
      if (storeState.currentStore == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No store selected',
        );
        return false;
      }

      final result = await _reportsProvider.getProfitabilityAnalysis(
        storeId: storeState.currentStore!['_id'],
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        state = state.copyWith(
          profitability: result['data'] ?? {},
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error cargando análisis de rentabilidad',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  Future<bool> loadSalesTrendsAnalysis({
    required String startDate,
    required String endDate,
  }) async {
    _initReportsProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final storeState = ref.read(storeProvider);
      if (storeState.currentStore == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No store selected',
        );
        return false;
      }

      final result = await _reportsProvider.getSalesTrendsAnalysis(
        storeId: storeState.currentStore!['_id'],
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        state = state.copyWith(
          salesTrends: result['data'] ?? {},
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error cargando análisis de tendencias',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  Future<bool> loadPeriodsComparison({
    required String currentStartDate,
    required String currentEndDate,
    required String previousStartDate,
    required String previousEndDate,
  }) async {
    _initReportsProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final storeState = ref.read(storeProvider);
      if (storeState.currentStore == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No store selected',
        );
        return false;
      }

      final result = await _reportsProvider.getPeriodsComparison(
        storeId: storeState.currentStore!['_id'],
        currentStartDate: currentStartDate,
        currentEndDate: currentEndDate,
        previousStartDate: previousStartDate,
        previousEndDate: previousEndDate,
      );

      if (result['success']) {
        state = state.copyWith(
          periodsComparison: result['data'] ?? {},
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error cargando comparación de períodos',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }

  void clearAllReports() {
    state = ReportsState();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});
