import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

class StoreListState {
  final List<Map<String, dynamic>>? stores;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const StoreListState({
    this.stores,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  StoreListState copyWith({
    List<Map<String, dynamic>>? stores,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      StoreListState(
        stores: stores ?? this.stores,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class StoreListNotifier extends StateNotifier<StoreListState> {
  final CacheService _cache = CacheService();

  StoreListNotifier() : super(const StoreListState());

  Future<void> loadStores({bool forceRefresh = false}) async {
    const cacheKey = 'store_list';

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('✅ Stores obtenidos del caché');
        state = state.copyWith(stores: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stores = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Store 1', 'city': 'Madrid'},
      ];

      _cache.set(cacheKey, stores, ttl: const Duration(minutes: 5));

      if (kDebugMode) print('✅ ${stores.length} stores cacheados');

      state = state.copyWith(stores: stores, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void invalidateStoreList() {
    _cache.invalidate('store_list');
    if (kDebugMode) print('🗑️ Cache de stores invalidado');
  }
}

final storeListProvider =
    StateNotifierProvider<StoreListNotifier, StoreListState>(
  (ref) => StoreListNotifier(),
);
