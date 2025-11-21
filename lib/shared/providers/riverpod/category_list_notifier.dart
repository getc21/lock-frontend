import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

class CategoryListState {
  final List<Map<String, dynamic>>? categories;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CategoryListState({
    this.categories,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CategoryListState copyWith({
    List<Map<String, dynamic>>? categories,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      CategoryListState(
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class CategoryListNotifier extends StateNotifier<CategoryListState> {
  final CacheService _cache = CacheService();

  CategoryListNotifier() : super(const CategoryListState());

  Future<void> loadCategories({bool forceRefresh = false}) async {
    const cacheKey = 'category_list';

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('✅ Categories obtenidas del caché');
        state = state.copyWith(categories: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Category 1'},
      ];

      _cache.set(cacheKey, categories, ttl: const Duration(minutes: 5));

      if (kDebugMode) print('✅ ${categories.length} categories cacheadas');

      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void invalidateCategoryList() {
    _cache.invalidate('category_list');
    if (kDebugMode) print('🗑️ Cache de categories invalidado');
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, CategoryListState>(
  (ref) => CategoryListNotifier(),
);
