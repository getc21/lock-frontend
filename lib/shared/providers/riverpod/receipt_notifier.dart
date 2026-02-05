import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../receipt_provider.dart' as receipt_api;
import 'auth_notifier.dart';
import '../../services/cache_service.dart';

// Estado de comprobantes
class ReceiptState {
  final List<Map<String, dynamic>> receipts;
  final Map<String, dynamic>? selectedReceipt;
  final bool isLoading;
  final String errorMessage;
  final Map<String, dynamic>? statistics;

  ReceiptState({
    this.receipts = const [],
    this.selectedReceipt,
    this.isLoading = false,
    this.errorMessage = '',
    this.statistics,
  });

  ReceiptState copyWith({
    List<Map<String, dynamic>>? receipts,
    Map<String, dynamic>? selectedReceipt,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? statistics,
  }) {
    return ReceiptState(
      receipts: receipts ?? this.receipts,
      selectedReceipt: selectedReceipt ?? this.selectedReceipt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      statistics: statistics ?? this.statistics,
    );
  }
}

// Notifier para comprobantes
class ReceiptNotifier extends StateNotifier<ReceiptState> {
  final Ref ref;
  final CacheService _cache = CacheService();

  ReceiptNotifier(this.ref) : super(ReceiptState());

  late receipt_api.ReceiptProvider _receiptProvider;

  void _initReceiptProvider() {
    final authState = ref.read(authProvider);
    _receiptProvider = receipt_api.ReceiptProvider(authState.token);
  }

  // Obtener estadísticas de comprobantes
  Future<Map<String, dynamic>?> getReceiptStatistics(String storeId) async {
    _initReceiptProvider();
    
    final cacheKey = 'receipt:stats:$storeId';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      state = state.copyWith(statistics: cached);
      return cached;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _receiptProvider.getReceiptStatistics(storeId);

      if (result['success']) {
        final stats = result['data'] as Map<String, dynamic>;
        _cache.set(cacheKey, stats, ttl: const Duration(minutes: 15));
        state = state.copyWith(statistics: stats, isLoading: false);
        return stats;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error obteniendo estadísticas',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  // Obtener comprobante por número
  Future<Map<String, dynamic>?> getReceiptByNumber({
    required String receiptNumber,
    required String storeId,
  }) async {
    _initReceiptProvider();
    
    final cacheKey = 'receipt:$receiptNumber:$storeId';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      state = state.copyWith(selectedReceipt: cached);
      return cached;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _receiptProvider.getReceiptByNumber(
        receiptNumber: receiptNumber,
        storeId: storeId,
      );

      if (result['success']) {
        final receipt = result['data'] as Map<String, dynamic>;
        _cache.set(cacheKey, receipt, ttl: const Duration(minutes: 30));
        state = state.copyWith(selectedReceipt: receipt, isLoading: false);
        return receipt;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Comprobante no encontrado',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  // Obtener comprobantes en rango de fechas
  Future<List<Map<String, dynamic>>?> getReceiptsByDateRange({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    _initReceiptProvider();
    
    final cacheKey = 'receipts:range:$storeId:$startDate:$endDate';
    final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) {
      state = state.copyWith(receipts: cached, isLoading: false);
      return cached;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _receiptProvider.getReceiptsByDateRange(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        final receipts = List<Map<String, dynamic>>.from(result['data']['receipts'] as List);
        _cache.set(cacheKey, receipts, ttl: const Duration(minutes: 15));
        state = state.copyWith(receipts: receipts, isLoading: false);
        return receipts;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error obteniendo comprobantes',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }

  void clearReceipts() {
    state = ReceiptState();
  }
}

// Provider
final receiptProvider = StateNotifierProvider<ReceiptNotifier, ReceiptState>((ref) {
  return ReceiptNotifier(ref);
});
