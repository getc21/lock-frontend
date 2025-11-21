import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

/// State para lista de suppliers
class SupplierListState {
  final List<Map<String, dynamic>>? suppliers;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SupplierListState({
    this.suppliers,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SupplierListState copyWith({
    List<Map<String, dynamic>>? suppliers,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      SupplierListState(
        suppliers: suppliers ?? this.suppliers,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Notifier con caching
class SupplierListNotifier extends StateNotifier<SupplierListState> {
  final CacheService _cache = CacheService();

  SupplierListNotifier() : super(const SupplierListState());

  Future<void> loadSuppliers({bool forceRefresh = false}) async {
    const cacheKey = 'supplier_list';

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('✅ Suppliers obtenidos del caché');
        state = state.copyWith(suppliers: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final suppliers = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Supplier 1', 'city': 'Madrid'},
      ];

      _cache.set(cacheKey, suppliers, ttl: const Duration(minutes: 5));

      if (kDebugMode) print('✅ ${suppliers.length} suppliers cacheados');

      state = state.copyWith(suppliers: suppliers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void invalidateSupplierList() {
    _cache.invalidate('supplier_list');
    if (kDebugMode) print('🗑️ Cache de suppliers invalidado');
  }
}

/// Provider global
final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, SupplierListState>(
  (ref) => SupplierListNotifier(),
);
